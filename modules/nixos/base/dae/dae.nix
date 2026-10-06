{ config, pkgs, lib, ... }:
let
  daeConfig = ./config.dae;

  # ------------------------------------------------------------------
  # dae 原生订阅
  #
  # 主/副订阅的 URL 仍由 agenix 加密保管(不落 git),由下面这个 oneshot
  # 服务拉取后落盘成 dae 可读的 file:// 订阅文件;config.dae 里再用
  # subtag(main_sub)/subtag(backup_sub) 按来源区分优先级。
  #
  # 这样做的原因:sing-box 的两个服务原本用 conflicts 互斥,只能跑其一,
  # 无法实现"主订阅优先 + 副订阅兜底";dae 原生订阅可让两者同时进节点池。
  # ------------------------------------------------------------------
  subDir = "/var/lib/dae";
  mainSubFile = "${subDir}/main.sub";
  backupSubFile = "${subDir}/backup.sub";

  mainSecret = config.age.secrets.subscriptions_main.path;
  backupSecret = config.age.secrets.subscriptions_backup.path;

  fetchScript = pkgs.writeShellScript "dae-sub-update" ''
    set -uo pipefail
    mkdir -p ${subDir}

    fetch() {
      local secret="$1" out="$2" name="$3" url
      if [ ! -s "$secret" ]; then
        echo "[dae-sub-update] $name: secret missing ($secret)" >&2
        return 1
      fi
      url="$(cat "$secret")"
      if curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 15 -o "$out.tmp" "$url"; then
        mv "$out.tmp" "$out"
        chmod 600 "$out"
        echo "[dae-sub-update] $name: updated ($(wc -c < "$out") bytes)"
      else
        rm -f "$out.tmp"
        echo "[dae-sub-update] $name: fetch failed, keeping existing file" >&2
        return 1
      fi
    }

    rc=0
    fetch ${mainSecret} ${mainSubFile} main || rc=1
    fetch ${backupSecret} ${backupSubFile} backup || rc=1
    exit $rc
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

  # 订阅文件目录(root 可读写即可)
  systemd.tmpfiles.rules = [
    "d ${subDir} 0700 root root -"
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
      # 拉完让 dae 重新读取订阅(daemon 未运行时 reload 会失败,忽略即可)
      ExecStartPost = [ "${pkgs.systemd}/bin/systemctl reload dae.service 2>/dev/null || true" ];
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
      # 启动前保证订阅文件存在(nixpkgs 模块已用 ExecStartPre 做配置校验,
      # 这里追加一条;开头的 "" 是 NixOS systemd 模块的列表重置约定)
      ExecStartPre = lib.mkAfter [ "${ensureSubsScript}" ];
    };
  };
}
