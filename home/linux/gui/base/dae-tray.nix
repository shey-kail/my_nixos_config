{ pkgs, ... }: {
  # dae 托盘图标(常驻状态指示 + 启停控制 + 查看当前节点/日志)
  #
  # 用户级服务:登录图形会话后自启、随会话退出而停止。
  # 托盘是 GTK/AppIndicator 程序,依赖 systemd 用户管理器里的图形环境变量
  # (DISPLAY / WAYLAND_DISPLAY / DBUS_SESSION_BUS_ADDRESS —— Plasma 登录时会
  # 导入到用户管理器,已确认存在)。
  #
  # 启停 dae 走 pkexec → polkit(桌面有 polkit-kde-agent,会弹密码框),
  # 因为 dae 是系统服务、托盘只是普通用户身份。
  systemd.user.services.dae-tray = {
    Unit = {
      Description = "dae tray indicator";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.dae-tray}/bin/dae-tray";
      Restart = "on-failure";
      RestartSec = "5s";
      StandardOutput = "journal";
      StandardError = "journal";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
