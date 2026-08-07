{ config, pkgs, lib, ... }:
let
  daeConfig = ./config.dae;
in {
  services.dae = {
    # 默认不启动。需要时手动 `sudo systemctl start dae`。
    # 若想开机自启,改为 true 或在该主机配置里 `services.dae.enable = true`。
    enable = false;
    openFirewall = {
      enable = true;
      port = 12345;
    };
    package = pkgs.dae;
    configFile = daeConfig;
  };

  # dae 作为主要流量控制器，依赖任一代理服务(singbox、singbox-backup 互斥)
  # 注意：dae负责所有DNS解析和流量分流，singbox仅作为节点池
  # 用 mkIf 包裹,enable=false 时不生成空壳服务
  systemd.services.dae = lib.mkIf config.services.dae.enable {
    unitConfig = {
      Description = "dae Service";
    };
    after = [ "singbox.service" "singbox-backup.service" ];
    wants = [ "singbox.service" "singbox-backup.service" ];
  };
}
