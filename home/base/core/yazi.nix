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
      # PDF 用 zathura 打开。
      # 注意:yazi 的 opener 是数组([[opener]]),每项带 name,不是 map。
      opener = [
        {
          name = "zathura";
          run = "zathura \"$@\"";
          desc = "Open PDF with Zathura";
          block = false;
        }
      ];
      open = {
        rules = [
          # yazi 的 open 规则用 mime(glob)或 url(正则)匹配,不支持 name
          { mime = "application/pdf"; use = [ "zathura" ]; }
        ];
      };
    };
  };
}
