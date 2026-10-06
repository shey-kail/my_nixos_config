{ config, pkgs, lib, ... }:
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

  # 配置落到真实路径 /etc/dae/config.dae(内容不含密钥,可安全放 store)
  environment.etc."dae/config.dae".source = daeConfig;

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

  # dae 作为主要流量控制器，依赖任一代理服务(singbox、singbox-backup 互斥)
  # 注意：dae负责所有DNS解析和流量分流,singbox 目前只作为节点池里的兜底节点
  systemd.services.dae = {
    # 服务保留但默认不自动启动;需要时手动 `sudo systemctl start dae`。
    # 覆盖 nixpkgs 的 wantedBy=[ "multi-user.target" ],必须用 mkForce。
    wantedBy = lib.mkForce [ ];
    unitConfig = {
      Description = "dae Service";
    };
    after = [ "singbox.service" "singbox-backup.service" "dae-sub-update.service" ];
    wants = [ "singbox.service" "singbox-backup.service" "dae-sub-update.service" ];
    serviceConfig = {
      # 不用 LoadCredential,直接用 /etc/dae/config.dae —— 这样 configDir 就是
      # /etc/dae,file:// 订阅(须与配置同目录)才能解析
      LoadCredential = lib.mkForce [ ];
      ExecStartPre = lib.mkForce [
        ""
        "${daeBin} validate -c ${cfgDir}/config.dae"
        "${ensureSubsScript}"
      ];
      ExecStart = lib.mkForce [
        ""
        "${daeBin} run --disable-timestamp -c ${cfgDir}/config.dae"
      ];
    };
  };
}
