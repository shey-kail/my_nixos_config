{
  pkgs,
  ...
}:
{
  # Hyprland Wayland 合成器。
  # 阶段 1:仅安装,SDDM 会自动出现 Hyprland session,KDE 不动,登录时手动切换。
  # hyprland.conf 由 `dms setup` 生成,这里不写死配置。
  programs.hyprland = {
    enable = true;

    # X11 应用兼容(部分老软件仍需要)
    xwayland.enable = true;
  };

  # xdg-desktop-portal:屏幕共享 / 文件选择器 / 通知 等需要。
  # Plasma6 模块原本会启用,这里显式声明以确保 Hyprland 切换后还能用。
  xdg.portal = {
    enable = true;
    # Hyprland 推荐使用 xdg-desktop-portal-hyprland(由 dms-shell 拉入,无需手动加)
  };

  # polkit: GUI 认证弹窗(GParted、mount 操作等)
  security.polkit.enable = true;
}
