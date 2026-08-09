{
  pkgs,
  ...
}: {
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
      # PDF 用 zathura 打开
      opener = {
        zathura = {
          run = "zathura \"$@\"";
          desc = "Open PDF with Zathura";
          block = false;
        };
      };
      open = {
        rules = [
          { name = "*.pdf"; use = [ "zathura" ]; }
        ];
      };
    };
  };
}
