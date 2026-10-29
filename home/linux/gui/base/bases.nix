{pkgs, ...}: {
  home.packages = with pkgs; [
    xarchiver
    # rfd(ArtCraft 等 Rust 应用)的文件对话框兜底:X11 portal 不可用时它调 zenity
    zenity
  ];
}
