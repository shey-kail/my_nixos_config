{lib, ...}: {
  boot.loader.systemd-boot = {
    enable = true;
    # we use Git for version control, so we don't need to keep too many generations.
    configurationLimit = lib.mkDefault 10;
    # 2K 屏原生 2560×1440 文字太小(2K 上 max 等于 2560×1440,固定像素字小);
    # "auto" 让 UEFI firmware 挑一个不太大的合适模式(通常是 1024×768 或文本模式)。
    # 注意:systemd-boot 的 consoleMode 不接受任意分辨率("1920x1080" 会报类型错),
    # 合法值只有 0/1/2/5/auto/max/keep。
    consoleMode = "auto";
  };

  boot.kernel.features.userNamespace.enable = true;

  # Chromium / Brave 在 flatpak 沙箱外启动时,zygote 进程需要 ptrace 子渲染进程。
  # 默认 ptrace_scope=1(受限)会阻止,导致 xdg-open / DMS 启动器调 Chromium 时崩:
  #   [FATAL:dbus/bus.cc] D-Bus connection was disconnected. Aborting.
  #   ptrace: Operation not permitted (1)
  # 终端 `flatpak run` 走 flatpak-spawn 旁路绕过,能开。
  # 1 = 仅允许同用户、同 ptracer 的进程 ptrace(YAMA 默认);跨用户拒绝。
  # 原先设为 0 放开了同 uid 进程互相 ptrace,在被攻破的浏览器/扩展场景下
  # 可被利用读取其他用户进程内存。Chromium 走 flatpak-spawn 仍可工作。
  boot.kernel.sysctl."kernel.yama.ptrace_scope" = 1;

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
