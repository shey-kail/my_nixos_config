{ config, lib, pkgs, ... }:

let
  ui-cfg = config.services.netflow-ui;
  netflow-cfg = config.services.netflow;
  ui-script = pkgs.writeText "netflow-ui.py" (builtins.readFile ./ui/app.py);

  # upstream main.htm → 4 个 LuCI 标记替换 → 渲染模板
  #   <%+header%>                                                → <!DOCTYPE html><html><head>...<body>
  #   <%+footer%>                                                → </body></html>
  #   build_url("admin","services","netflow","api")             → /api
  #   build_url("admin","services","netflow","upload_core")      → /upload_core
  # git 仓库不存 verbatim 1991 行,只在 nix store 里
  rawTemplate = "${netflow-cfg.package}/share/netflow/main.htm";
  templateHtml = pkgs.runCommand "netflow-template.html" { } ''
    cp ${rawTemplate} $out
    chmod +w $out
    # 4 个 LuCI 标记一次性 sed 替换:
    #   <%+header%>                                                → <!DOCTYPE html>...<body>
    #   <%+footer%>                                                → </body></html>
    #   build_url("admin","services","netflow","api")             → /api
    #   build_url("admin","services","netflow","upload_core")     → /upload_core
    sed -i \
      -e 's|<%+header%>|<!DOCTYPE html>\n<html><head><meta charset="utf-8"><title>青云梯_Lite</title></head><body>|' \
      -e 's|<%+footer%>|</body></html>|' \
      -e 's|<%=luci\.dispatcher\.build_url("admin", "services", "netflow", "api")%>|/api|' \
      -e 's|<%=luci\.dispatcher\.build_url("admin","services","netflow","upload_core")%>|/upload_core|' \
      $out
  '';
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
      description = "netflow web UI (port of upstream LuCI component)";
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
        # Hardening:UI 是只转发 + 渲染,不写敏感路径
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        # 只需要 loopback 访问 netflow backend
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        Environment = [
          "NETFLOW_API_PORT=${builtins.toString netflow-cfg.settings.backendPort}"
          "PORT=${builtins.toString ui-cfg.port}"
          "NETFLOW_TEMPLATE=${templateHtml}"
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
