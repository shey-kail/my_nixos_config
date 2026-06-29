{
  pkgs,
  lib,
  ...
}:
{
  # DankMaterialShell:基于 Quickshell 的 Wayland shell,跑在 Hyprland 上。
  # 阶段 1:仅装好,hyprland.conf / binds 由 `dms setup` 在登录后生成。
  programs.dms-shell = {
    enable = true;

    # user 级 systemd 自启(必须显式开,默认 false)
    systemd.enable = true;

    # 核心功能开关
    enableSystemMonitoring = true; # dgop:CPU/内存/温度小部件
    enableDynamicTheming = false; # matugen:壁纸自动取色配色(关掉)
    enableClipboardPaste = true; # wtype:剪贴板历史粘贴模拟按键
    enableVPN = true; # NetworkManager VPN 入口

    # enableAudioWavelength / enableCalendarEvents 保持默认(false)
    # 想用 cava 可视化或 khal 日历再单独开
  };

  # ============================================================
  # Hyprland Wayland 合成器
  # hyprland.conf 由 `dms setup` 生成,这里不写死配置。
  # 自启项 `dms run` / `fcitx5 -d` 在 hyprland.conf 里(家目录天然持久)。
  # ============================================================
  programs.hyprland = {
    enable = true;
    xwayland.enable = true; # X11 兼容

    # UWSM(Universal Wayland Session Manager):让 hyprland 走 systemd user 路径
    # greetd exec `uwsm start -- hyprland`,uwsm 内部用 systemd 启 hyprland,
    # 自动 trigger graphical-session.target / wayland-session@Hyprland.target,
    # dms.service 的 Requisite= 拿到满足,bar/壁纸自动起。
    withUWSM = true;
  };

  # ============================================================
  # 登录管理器: greetd + tuigreet (TUI 轻量)
  # 不在 tuigreet 里写死 --cmd,登录后让 tuigreet 弹命令输入框,
  # 用户在 greetd 提示里手动输入要 exec 的命令(默认填 `uwsm start -- hyprland`)。
  # --remember-session 记住上次选 session,下次默认选中。
  # --time-format 用 chrono strftime 子集;%a 始终英文(chrono 默认 POSIX locale),
  # 不会被系统 LC_TIME=zh_CN 影响。
  # --sessions 显式指定只扫 system-path 下的 wayland-sessions/,避免 nixpkgs 的
  # pkgs.desktops 聚合(-desktops symlink farm)和 system-path 暴露同一份 hyprland .desktop
  # 导致 tuigreet 显示 4 条(它不去重)。XDG_DATA_DIRS 在 systemd unit 上设会被 PAM
  # startSession 重置,所以走 CLI 参数。
  # ============================================================
  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --time-format '%Y-%m-%d %a %H:%M' --asterisks --remember-session --sessions /run/current-system/sw/share/wayland-sessions";
        user = "greeter";
      };
    };
  };

  # ============================================================
  # KDE Connect — 纯用户态 daemon,不依赖 plasma6
  # ============================================================
  programs.kdeconnect.enable = true;
  networking.firewall = {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
  };

  # ============================================================
  # xdg-desktop-portal — 屏幕共享/文件选择器/通知(wayland 通用)
  # ============================================================
  xdg.portal = {
    enable = true;
  };

  # polkit — GUI 认证弹窗
  security.polkit.enable = true;

  # ============================================================
  # Qt 主题栈: qt6ct / qt5ct / kvantum 引擎
  # 让 Qt5 + Qt6 程序统一遵循用户配色和图标主题。
  # 之前 KDE 时代通过 plasma 主题自动管,Hyprland 下需要手动设。
  #
  # 工具 / 引擎:
  # - qt6ct: Qt6 配置工具(读 KDE 颜色方案、选图标、选 style)
  # - qt5ct: Qt5 同上(老 Qt5 app 需要)
  # - qtstyleplugin-kvantum (Qt5 + Qt6): kvantum 主题引擎 plugin
  # 选主题:在 qt6ct 的 Style 下拉里选 "kvantum",然后用主题文件。
  # ============================================================
  environment.systemPackages = [
    pkgs.qt6Packages.qt6ct
    pkgs.libsForQt5.qt5ct
    pkgs.qt6Packages.qtstyleplugin-kvantum
    pkgs.libsForQt5.qtstyleplugin-kvantum
  ];

  # 让 Qt 程序启动时自动用 qt6ct 配置
  # Hyprland session 会通过 /etc/profile 继承这个变量
  environment.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
    # 禁用 KDE/Kvantum 强制覆盖(避免双 theme 冲突)
    QT_STYLE_OVERRIDE = "";
  };
}
