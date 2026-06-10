{lib, ...}: {
  boot.loader.systemd-boot = {
    enable = true;
    # we use Git for version control, so we don't need to keep too many generations.
    configurationLimit = lib.mkDefault 10;
    # pick the highest resolution for systemd-boot's console.
    consoleMode = lib.mkDefault "max";
  };
  

  boot.kernel.features.userNamespace.enable = true;

  # Chromium / Brave 在 flatpak 沙箱外启动时,zygote 进程需要 ptrace 子渲染进程。
  # 默认 ptrace_scope=1(受限)会阻止,导致 xdg-open / DMS 启动器调 Chromium 时崩:
  #   [FATAL:dbus/bus.cc] D-Bus connection was disconnected. Aborting.
  #   ptrace: Operation not permitted (1)
  # 终端 `flatpak run` 走 flatpak-spawn 旁路绕过,能开。
  # 设 0 = 允许同用户进程互相 ptrace;对单用户桌面系统影响小。
  boot.kernel.sysctl."kernel.yama.ptrace_scope" = 0;

  boot.loader.timeout = lib.mkDefault 8; # wait for x seconds to select the boot entry

  # for power management
  services = {
    power-profiles-daemon = {
      enable = true;
    };
    upower.enable = true;
  };
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;
}
