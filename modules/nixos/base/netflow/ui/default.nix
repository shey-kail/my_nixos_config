{ config, lib, pkgs, ... }:

let
  ui-cfg = config.services.netflow-ui;
  netflow-cfg = config.services.netflow;
  ui-script = pkgs.writeText "netflow-ui.py" (builtins.readFile ./ui.py);
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
    systemd.services.netflow-ui = {
      description = "netflow web UI";
      wantedBy = [ "multi-user.target" ];
      after = [ "netflow.service" ];
      requires = lib.optionals netflow-cfg.enable [ "netflow.service" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        Environment = [
          "NETFLOW_API_PORT=${builtins.toString netflow-cfg.settings.backendPort}"
          "PORT=${builtins.toString ui-cfg.port}"
        ];
        ExecStart = pkgs.writeScript "netflow-ui-start" ''
          #!${pkgs.bash}/bin/bash
          ${pkgs.python3}/bin/python3 ${ui-script}
        '';
      };
    };
  };
}