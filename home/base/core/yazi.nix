{
  pkgs,
  ...
}:
{
  # terminal file manager
  programs.yazi = {
    enable = true;
    shellWrapperName = "yy";
    package = pkgs.yazi;
    # Changing working directory when exiting Yazi
    enableBashIntegration = true;
    settings = {
      mgr = {
        # show_hidden = true;
        sort_dir_first = true;
        linemode = "size";
      };
    };
  };
  # 注意:不要在这里自定义 yazi 的 open.rules / opener 来改 PDF 打开方式——
  # 自定义 open.rules 会替换 yazi 内置规则,jpg/mp4 等会失去默认打开方式。
  # PDF 默认应用(zathura)统一在 home/linux/gui/base/xdg.nix 的 mimeApps 里管理。
}
