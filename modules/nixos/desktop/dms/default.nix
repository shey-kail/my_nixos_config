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
    enableSystemMonitoring = true;   # dgop:CPU/内存/温度小部件
    enableDynamicTheming = true;     # matugen:壁纸自动取色配色
    enableClipboardPaste = true;     # wtype:剪贴板历史粘贴模拟按键
    enableVPN = true;                # NetworkManager VPN 入口

    # enableAudioWavelength / enableCalendarEvents 保持默认(false)
    # 想用 cava 可视化或 khal 日历再单独开
  };
}
