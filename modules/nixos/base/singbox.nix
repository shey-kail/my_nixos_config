{ config, pkgs, lib, ... }:
let
  # 物理存放路径
  persistSubDir = "/var/lib/singbox/subscriptions";

  # singbox config file
  configFile = "${persistSubDir}/config.json";
  configTmpFile = "${persistSubDir}/config.json.new";

  # singbox template files
  templateFile = ./template.json;

  # subscription urls
  secret_path = config.age.secrets.singbox_subscriptions.path;

  # singbox dashboard
  metacubexdDashboard = pkgs.metacubexd;


  # 配置clash2singbox
  # clash2singbox-custom = pkgs.buildGoModule rec {
  #   pname = "clash2singbox";
  #   version = "d3d4133"; # 你指定的 commit hash
  #   src = pkgs.fetchFromGitHub {
  #     owner = "xmdhs";
  #     repo = "clash2singbox";
  #     rev = version;
  #     sha256 = "sha256-dH/G/RQjuawIco3DvAb9IYdhcWcUhqrKTy+jbd17bwM=";
  #   };
  #   vendorHash = "sha256-yyNECSxGhg32wDB/wRdukyvLDwYq9S3EE078T0ZcfKY=";
  #   meta = with pkgs.lib; {
  #     description = "Convert Clash configuration to Sing-box format";
  #     homepage = "https://github.com/xmdhs/clash2singbox";
  #     license = licenses.mit;
  #   };
  # };
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

  # 1. 订阅更新服务
  systemd.services.singbox-sub-update = {
    description = "Update singbox subscriptions";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [ coreutils curl gnused jq systemd ];

    script = ''
      mkdir -p ${persistSubDir}

      # 获取订阅配置并应用一系列转换（合并为单个jq命令以避免多行管道语法问题）
      # 1. 移除 type 为 "tun" 的 inbounds
      # 2. 将 type 为 "mixed" 的 inbounds 绑定到 127.0.0.1:9050
      # 3. 设置日志配置：启用日志、级别为 error、带时间戳
      # 4. 设置默认域名解析器为 dns_direct，并移除所有包含 clash_mode 字段的规则
      # 5. 设置AI服务默认为新加坡节点
      # 6. 设置测试延迟的地址为http://www.google.com/generate_204
      # 7. 启用 Clash API，配置外部控制地址、Web UI 路径和空 secret
      curl -s "$(cat ${secret_path})" | \
        jq --arg dashboard "${metacubexdDashboard}" '.inbounds |= map(select(.type != "tun")) | .inbounds |= map(if .type == "mixed" then (.listen = "127.0.0.1" | .listen_port = 9050) else . end) | .log = {"disabled": false, "level": "error", "timestamp": true} | .route |= (.default_domain_resolver = "dns_direct" | .rules |= map(select(.clash_mode | not?))) | .outbounds |= map(if (.type == "selector" and .tag == "💬 AI 服务") then .default = "🇸🇬 Singapore" else . end) | .experimental.clash_api.default_latency_url //= "http://www.google.com/generate_204" | .experimental += { "clash_api": { "external_controller": "127.0.0.1:9090", "external_ui": $dashboard, "secret": "" } }' > "${configTmpFile}"

      # Check if the generation was successful AND the new file is not empty
      if [ -s ${configTmpFile} ]; then
        echo "Update successful. Applying new configuration."
        mv ${configTmpFile} ${configFile}
      else
        echo "Warning: Update fetch failed or produced an empty file. Keeping existing config."
        rm -f ${configTmpFile} # Clean up the failed artifact
        exit 0 # Exit successfully without applying changes or reloading
      fi

      # Finalize permissions and reload. This only runs on successful update.
      echo "Finalizing permissions and reloading service."
      chown singbox:singbox ${configFile}
      systemctl reload-or-try-restart singbox.service
    '';

    serviceConfig = {
      Type = "oneshot";
      User = "root"; # 需要 root 权限来读取 age secret 和写入 /var/lib
    };
  };

  # 2. 定时器配置
  systemd.timers.singbox-sub-update = {
    description = "Timer for singbox subscription update";
    timerConfig = {
      OnBootSec = "10m";          # 开机 10 分钟后执行第一次
      OnUnitActiveSec = "12h";   # 之后每 12 小时执行一次
      Unit = "singbox-sub-update.service";
    };
    wantedBy = [ "timers.target" ];
  };

  # 3. singbox 主服务
  systemd.services.singbox = {
    description = "singbox service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    path = [ pkgs.systemd ]; # for systemctl in ExecStartPre

    # 权限设置：允许 Exec*Pre/Post 以 root 身份运行
    serviceConfig.PermissionsStartOnly = true;
    # 启动前置脚本：如果配置文件不存在，则运行一次更新脚本
    serviceConfig.ExecStartPre = pkgs.writeShellScript "singbox-pre-start" ''
      set -e
      # The -s operator checks if the file exists AND is not empty.
      if [ ! -s "${configFile}" ]; then
          echo "singbox config not found or is empty, running initial subscription update..."
          # --wait will block until the service is finished.
          systemctl start --wait singbox-sub-update.service
      fi
    '';

    serviceConfig = {
      Type = "simple";
      User = "singbox";
      Group = "singbox";
      ExecStart = "${pkgs.sing-box}/bin/sing-box run -c ${configFile}";
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      Restart = "on-failure";
      RestartSec = 10;
      Environment = [ "ENABLE_DEPRECATED_SPECIAL_OUTBOUNDS=true" ];

      # 设置工作目录以便于缓存文件可以写入
      WorkingDirectory = "/var/lib/singbox";

      # 安全和能力设置
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" "CAP_NET_RAW" ];
      AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" "CAP_NET_RAW" ];
      NoNewPrivileges = true;
      # 使用 less restrictive than strict to allow necessary writes for cache file
      ProtectSystem = "true";
      # 允许访问特定的可写路径
      ReadWritePaths = [ "/var/lib/singbox" ];
      PrivateTmp = false;  # 需要允许访问 /tmp 及当前目录供缓存使用
      ProtectHome = true;
      PrivateDevices = true;
    };
  };
}
