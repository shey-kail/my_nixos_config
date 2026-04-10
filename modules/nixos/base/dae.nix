{ config, pkgs, lib, ... }:
let
  daeConfig = ./config.dae;
in {
  services.dae = {
    enable = true;
    openFirewall = {
      enable = true;
      port = 12345;
    };
    package = pkgs.dae;
    configFile = daeConfig;
  };

  # dae 作为主要流量控制器，依赖 singbox 服务
  # 注意：dae负责所有DNS解析和流量分流，singbox仅作为节点池
  # dae 只在 singbox 或 singbox-backup 运行时才运行
  systemd.services.dae = {
    unitConfig = {
      Description = "dae Service";
    };
    after = [ "singbox.service" "singbox-backup.service" ];
  };
}
