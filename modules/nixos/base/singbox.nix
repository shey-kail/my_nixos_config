{ config, pkgs, lib, ... }:
let
  # 物理存放路径
  persistSubDir = "/var/lib/singbox/subscriptions";

  # 配置文件路径
  mainConfigFile = "${persistSubDir}/config_main.json";
  backupConfigFile = "${persistSubDir}/config_backup.json";

  # 订阅 secret paths
  mainSecretPath = config.age.secrets.subscriptions_main.path;
  backupSecretPath = config.age.secrets.subscriptions_backup.path;

  # singbox dashboard
  metacubexdDashboard = pkgs.metacubexd;

  # subpipe
  subpipe = pkgs.subpipe;

  # 模板文件
  mainTemplate = pkgs.writeText "main-template.json" (builtins.readFile ./singbox-templates/gouji_template.json);
  backupTemplate = pkgs.writeText "backup-template.json" (builtins.readFile ./singbox-templates/ncr_template.json);

  # singbox subscriptions update script
  updateScript = pkgs.writeShellScriptBin "singbox-update-script" ''
    ${builtins.readFile ./singbox-update.sh}
  '';
in
{
  # 0. singbox 用户和目录
  users.users.singbox = {
    isSystemUser = true;
    group = "singbox";
    home = persistSubDir;
  };
  users.groups.singbox = {};

  # 为 Dashboard 打开防火墙端口
  networking.firewall.allowedTCPPorts = [ 9090 ];

  # 创建 singbox 需要的目录并设置权限
  systemd.tmpfiles.rules = [
    "d /var/lib/singbox 0750 root singbox -"
    "d ${persistSubDir} 0750 singbox singbox -"
  ];

  # ============================================
  # 1. 订阅更新服务
  # ============================================
  systemd.services.singbox-sub-update = {
    description = "Update singbox subscriptions (main and backup)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [ coreutils curl gnused jq subpipe ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      ${updateScript}/bin/singbox-update-script \
        --main-secret-path ${mainSecretPath} \
        --backup-secret-path ${backupSecretPath} \
        --main-template ${mainTemplate} \
        --backup-template ${backupTemplate} \
        --dashboard-path ${metacubexdDashboard}
    '';
  };

  # 定时器配置（每12小时自动更新）
  systemd.timers.singbox-sub-update = {
    description = "Timer for singbox subscription update";
    timerConfig = {
      OnBootSec = "10m";
      OnUnitActiveSec = "12h";
      Unit = "singbox-sub-update.service";
    };
    wantedBy = [ "timers.target" ];
  };

  # ============================================
  # 2. singbox 主服务
  # ============================================
  systemd.services.singbox = {
    description = "singbox service (main subscription)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    path = [ pkgs.systemd ];

    serviceConfig.PermissionsStartOnly = true;
    serviceConfig.ExecStartPre = pkgs.writeShellScript "singbox-pre-start" ''
      set -e
      if [ ! -s "${mainConfigFile}" ]; then
          echo "singbox main config not found, running subscription update..."
          systemctl start --wait singbox-sub-update.service
      fi
    '';

    serviceConfig = {
      Type = "simple";
      User = "singbox";
      Group = "singbox";
      ExecStart = "${pkgs.sing-box}/bin/sing-box run -c ${mainConfigFile}";
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      Restart = "on-failure";
      RestartSec = 10;
      Environment = [ "ENABLE_DEPRECATED_SPECIAL_OUTBOUNDS=true" ];

      WorkingDirectory = "/var/lib/singbox";

      CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" "CAP_NET_RAW" ];
      AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" "CAP_NET_RAW" ];
      NoNewPrivileges = true;
      ProtectSystem = "true";
      ReadWritePaths = [ "/var/lib/singbox" ];
      PrivateTmp = false;
      ProtectHome = true;
      PrivateDevices = true;
    };
  };

  # ============================================
  # 3. singbox 备用服务
  # ============================================
  systemd.services.singbox-backup = {
    description = "singbox service (backup subscription)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    path = [ pkgs.systemd ];

    serviceConfig.PermissionsStartOnly = true;
    serviceConfig.ExecStartPre = pkgs.writeShellScript "singbox-backup-pre-start" ''
      set -e
      if [ ! -s "${backupConfigFile}" ]; then
          echo "singbox backup config not found, running subscription update..."
          systemctl start --wait singbox-sub-update.service
      fi
    '';

    serviceConfig = {
      Type = "simple";
      User = "singbox";
      Group = "singbox";
      ExecStart = "${pkgs.sing-box}/bin/sing-box run -c ${backupConfigFile}";
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      Restart = "on-failure";
      RestartSec = 10;
      Environment = [ "ENABLE_DEPRECATED_SPECIAL_OUTBOUNDS=true" ];

      WorkingDirectory = "/var/lib/singbox";

      CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" "CAP_NET_RAW" ];
      AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" "CAP_NET_RAW" ];
      NoNewPrivileges = true;
      ProtectSystem = "true";
      ReadWritePaths = [ "/var/lib/singbox" ];
      PrivateTmp = false;
      ProtectHome = true;
      PrivateDevices = true;
    };
  };
}
