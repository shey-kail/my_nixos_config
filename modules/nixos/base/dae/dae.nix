{ config, pkgs, lib, myvars, ... }:
let
  daeConfig = ./config.dae;
  daeBin = lib.getExe pkgs.dae;

  # ------------------------------------------------------------------
  # dae 原生订阅
  #
  # 主/副订阅的 URL 仍由 agenix 加密保管(不落 git),由下面这个 oneshot
  # 服务拉取后写进 dae 的"配置目录"。
  #
  # 为什么必须同目录(读源码确认):
  #   cmd/run_controlplane.go 用 filepath.Dir(cfgFile) 作为 configDir,
  #   common/subscription.ResolveFile 做 filepath.Join(configDir, ...)
  #   并调用 common.EnsureFileInSubDir 校验"订阅文件必须在 configDir 内",
  #   否则报 "file is out of scope"。
  # 又因为 nixpkgs 的 dae 模块默认用 LoadCredential 把配置放到
  # /run/credentials/dae.service/,那个目录每次启动重建、无法持久放订阅,
  # 所以这里改为使用真实路径 /etc/dae(configDir 即 /etc/dae)。
  # ------------------------------------------------------------------
  cfgDir = "/etc/dae";
  mainSubFile = "${cfgDir}/main.sub";
  backupSubFile = "${cfgDir}/backup.sub";

  mainSecret = config.age.secrets.subscriptions_main.path;
  backupSecret = config.age.secrets.subscriptions_backup.path;

  fetchScript = pkgs.writeShellScript "dae-sub-update" ''
    set -uo pipefail
    mkdir -p ${cfgDir}

    # 拉取订阅。要点:
    #   - 记录 HTTP 状态码与字节数,失败原因一目了然
    #   - 空内容(0 字节)绝不覆盖已有文件 —— 订阅过期/被拦截时常见的表现,
    #     否则会把好配置清掉
    fetch() {
      local secret="$1" out="$2" name="$3" url code size
      if [ ! -s "$secret" ]; then
        echo "[dae-sub-update] $name: secret missing ($secret)" >&2
        return 1
      fi
      url="$(cat "$secret")"
      code="$(curl -sSL --retry 3 --retry-delay 2 --connect-timeout 20 \
                -o "$out.tmp" -w '%{http_code}' "$url" 2>/dev/null)" || code="curl-error"
      size=0
      [ -f "$out.tmp" ] && size="$(wc -c < "$out.tmp")"

      case "$code" in
        2??)
          if [ "$size" -gt 0 ]; then
            mv "$out.tmp" "$out"
            chmod 600 "$out"
            echo "[dae-sub-update] $name: updated (http $code, $size bytes)"
            return 0
          fi
          echo "[dae-sub-update] $name: EMPTY body (http $code, 0 bytes) — 订阅可能已过期或被拦截,保留旧文件" >&2
          ;;
        *)
          echo "[dae-sub-update] $name: HTTP/网络失败 (code=$code) — 保留旧文件" >&2
          ;;
      esac
      rm -f "$out.tmp"
      return 1
    }

    rc=0
    fetch ${mainSecret} ${mainSubFile} main || rc=1
    fetch ${backupSecret} ${backupSubFile} backup || rc=1
    exit $rc
  '';

  # 拉完订阅后让 dae 重新加载。
  # 注意:ExecStart* 不经过 shell,写成 "... 2>/dev/null || true" 会被当成
  # 参数传给 systemctl(之前就是这样报 Invalid unit name 的),所以必须包成脚本。
  reloadScript = pkgs.writeShellScript "dae-reload-after-subs" ''
    ${pkgs.systemd}/bin/systemctl is-active --quiet dae.service || exit 0
    ${pkgs.systemd}/bin/systemctl reload dae.service || true
  '';

  # dae 启动前确保订阅文件存在(拉取失败也不阻塞启动:dae 可先用本地节点)
  ensureSubsScript = pkgs.writeShellScript "dae-subs-ensure" ''
    if [ ! -s ${mainSubFile} ] || [ ! -s ${backupSubFile} ]; then
      echo "[dae] subscription files missing, fetching..."
      systemctl start --wait dae-sub-update.service || true
    fi
  '';

  # 把配置以 0600 落到 /etc/dae/config.dae。
  #
  # 不能直接用 environment.etc:它生成的是指向 nix store 的软链,而 store 里的
  # 文件是 0444(dae 会拒绝:"permissions 0644 are too open; requires the file
  # is NOT writable by the same group and NOT accessible by others")。
  # 配置文件本身不含密钥(订阅 URL 在 /etc/dae/*.sub,已是 0600),但仍按 dae
  # 的要求收紧权限。
  installConfigScript = pkgs.writeShellScript "dae-install-config" ''
    set -e
    mkdir -p ${cfgDir}
    chmod 0700 ${cfgDir}
    # 先 unlink:旧版本用 environment.etc 生成的是指向 store 的软链,
    # 而 install 默认会跟随目标软链写入(会去写只读的 store 文件)
    rm -f ${cfgDir}/config.dae
    ${pkgs.coreutils}/bin/install -m 0600 ${daeConfig} ${cfgDir}/config.dae
    # 显式再 chmod 一次,确保不受任何 umask/实现差异影响
    chmod 0600 ${cfgDir}/config.dae
  '';

  # dae 启停时给桌面发通知(托盘气泡)。
  #
  # dae 是系统服务(root),而通知要投递到用户会话的 D-Bus,所以要:
  #   1. 找到该用户的活跃图形会话对应的 session bus(/run/user/<uid>/bus)
  #   2. 用 runuser 切到该用户身份再 notify-send(通知守护进程只接受同 uid 的消息)
  # 没有图形会话(例如从 SSH 启动、或开机阶段)时静默跳过。
  notifyScript = pkgs.writeShellScript "dae-notify" ''
    mode="''${1:-}"
    case "$mode" in
      start) title="dae 已启动"; body="代理已接管流量(按优先级选节点)"; icon="network-vpn" ;;
      stop)  title="dae 已停止"; body="流量已恢复直连";                  icon="network-offline" ;;
      *) exit 0 ;;
    esac

    user="${myvars.username}"
    uid="$(${pkgs.coreutils}/bin/id -u "$user" 2>/dev/null)" || exit 0
    runtime="/run/user/$uid"
    bus="$runtime/bus"
    [ -S "$bus" ] || exit 0

    # 只有存在活跃图形会话时才提示(避免 SSH/开机阶段刷错误)
    ${pkgs.systemd}/bin/loginctl list-sessions --no-legend 2>/dev/null \
      | while read -r sid s_uid s_user _rest; do
          [ "$s_user" = "$user" ] || continue
          state="$(${pkgs.systemd}/bin/loginctl show-session "$sid" -p State --value 2>/dev/null)"
          [ "$state" = "active" ] || continue
          echo found
        done | grep -q found || exit 0

    ${pkgs.util-linux}/bin/runuser -u "$user" -- \
      ${pkgs.coreutils}/bin/env \
        DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
        XDG_RUNTIME_DIR="$runtime" \
        ${pkgs.libnotify}/bin/notify-send -a dae -i "$icon" -u normal -t 8000 "$title" "$body" \
      2>/dev/null || true
  '';
in {
  services.dae = {
    # enable 必须为 true,让 nixpkgs 生成完整的 dae.service(含 ExecStart/配置校验)。
    # "不自动启动"靠下方 systemd.services.dae.wantedBy = lib.mkForce [] 实现。
    enable = true;
    openFirewall = {
      enable = true;
      port = 12345;
    };
    package = pkgs.dae;
    configFile = daeConfig;
  };

  # 配置以 0600 复制到 /etc/dae/config.dae(见 installConfigScript 注释:
  # environment.etc 的 0444 软链会被 dae 以 "permissions are too open" 拒绝)。
  # 这里在 activation 阶段先放一份,dae 启动时(ExecStartPre)还会再刷一次。
  system.activationScripts.dae-config = ''
    mkdir -p ${cfgDir}
    chmod 0700 ${cfgDir}
    rm -f ${cfgDir}/config.dae
    ${pkgs.coreutils}/bin/install -m 0600 ${daeConfig} ${cfgDir}/config.dae
    chmod 0600 ${cfgDir}/config.dae
  '';

  # 配置目录 + 订阅文件占位
  systemd.tmpfiles.rules = [
    "d ${cfgDir} 0700 root root -"
  ];

  # 订阅拉取(oneshot;不设 wantedBy,由 dae 启动前按需拉起)
  systemd.services.dae-sub-update = {
    description = "Fetch dae subscriptions (main + backup) from agenix secrets";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [ coreutils curl ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = fetchScript;
      # 拉完让 dae 重新读取订阅(daemon 未运行时脚本自己退出 0)
      ExecStartPost = [ reloadScript ];
    };
  };

  # 定时刷新订阅。默认不启用,需要时:
  #   sudo systemctl enable --now dae-sub-update.timer
  systemd.timers.dae-sub-update = {
    description = "Timer for dae subscription update";
    timerConfig = {
      OnBootSec = "10m";
      OnUnitActiveSec = "12h";
      Unit = "dae-sub-update.service";
    };
  };

  # dae 是唯一的代理出口:自己吃订阅、选节点、做 DNS 与流量分流。
  # (原先的 sing-box 节点池 + subpipe 订阅转换已在迁移完成后移除)
  systemd.services.dae = {
    # 服务保留但默认不自动启动;需要时手动 `sudo systemctl start dae`。
    # 覆盖 nixpkgs 的 wantedBy=[ "multi-user.target" ],必须用 mkForce。
    wantedBy = lib.mkForce [ ];
    unitConfig = {
      Description = "dae Service";
    };
    after = [ "dae-sub-update.service" ];
    wants = [ "dae-sub-update.service" ];
    serviceConfig = {
      # 不用 LoadCredential,直接用 /etc/dae/config.dae —— 这样 configDir 就是
      # /etc/dae,file:// 订阅(须与配置同目录)才能解析
      LoadCredential = lib.mkForce [ ];
      # 顺序:先按 0600 落配置(否则 dae 报 permissions too open),
      # 再校验配置,最后确保订阅文件存在
      ExecStartPre = lib.mkForce [
        ""
        "${installConfigScript}"
        "${daeBin} validate -c ${cfgDir}/config.dae"
        "${ensureSubsScript}"
      ];
      ExecStart = lib.mkForce [
        ""
        "${daeBin} run --disable-timestamp -c ${cfgDir}/config.dae"
      ];
      # 启停时在桌面(托盘)弹通知
      ExecStartPost = [ "${notifyScript} start" ];
      ExecStopPost = [ "${notifyScript} stop" ];
    };
  };
}
