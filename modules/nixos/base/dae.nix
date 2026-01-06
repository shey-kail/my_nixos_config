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
  systemd.services.dae = {
    unitConfig = {
      Description = "dae Service";
      # 当 sing-box 启动时，dae 也会被尝试启动
      After = [ "singbox.service" ];
      # 绑定关系：如果 sing-box 停止或崩溃，dae 也会立即停止（作为基础保障）
      BindsTo = [ "singbox.service" ];
    };
  };
}
