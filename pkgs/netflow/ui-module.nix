{ config, lib, pkgs, ... }:

let
  ui-cfg = config.services.netflow-ui;
  netflow-cfg = config.services.netflow;
  ui-script = pkgs.writeText "netflow-ui.py" (builtins.readFile ./ui/app.py);
in
{
  options.services.netflow-ui = {
    enable = lib.mkEnableOption "netflow web UI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.python3.withPackages (p: [ p.flask p.requests ]);
      description = "UI package";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9090;
      description = "Web UI port";
    };
  };

  config = lib.mkIf ui-cfg.enable {
    assertions = [
      {
        assertion = netflow-cfg.enable;
        message = "services.netflow-ui requires services.netflow to also be enabled.";
      }
    ];

    systemd.services.netflow-ui = {
      description = "netflow web UI";
      wantedBy = [ "multi-user.target" ];
      # netflow-ui 是 netflow 的控制面板:
      # requires 拉起(netflow 启 → netflow-ui 启)
      # partOf 跟停(netflow 停 → netflow-ui 停)
      after = [ "netflow.service" ];
      requires = [ "netflow.service" ];
      partOf = [ "netflow.service" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        Environment = [
          "NETFLOW_API_PORT=${builtins.toString netflow-cfg.settings.backendPort}"
          "PORT=${builtins.toString ui-cfg.port}"
        ];
        ExecStart = pkgs.writeScript "netflow-ui-start" ''
          #!${pkgs.bash}/bin/bash
          # 用 ui-cfg.package(python3.withPackages flask/requests),不是裸 pkgs.python3
          ${ui-cfg.package}/bin/python3 ${ui-script}
        '';
      };
    };
  };
}
