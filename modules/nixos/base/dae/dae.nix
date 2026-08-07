{ config, pkgs, lib, ... }:
let
  daeConfig = ./config.dae;
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

  # dae 作为主要流量控制器，依赖任一代理服务(singbox、singbox-backup 互斥)
  # 注意：dae负责所有DNS解析和流量分流，singbox仅作为节点池
  systemd.services.dae = {
    # 服务保留但默认不自动启动;需要时手动 `sudo systemctl start dae`。
    # 覆盖 nixpkgs 的 wantedBy=[ "multi-user.target" ],必须用 mkForce。
    wantedBy = lib.mkForce [ ];
    unitConfig = {
      Description = "dae Service";
    };
    after = [ "singbox.service" "singbox-backup.service" ];
    wants = [ "singbox.service" "singbox-backup.service" ];
  };
}
