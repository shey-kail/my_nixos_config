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
      # PDF 用 zathura 打开。
      # yazi 的 opener 是 map(键=opener名),每个值是该 opener 的候选数组(fallback 链)。
      # 注意:opener 顶层是 map,不是数组;opener 值才是数组。
      opener = {
        zathura = [
          {
            run = "zathura \"$@\"";
            desc = "Open PDF with Zathura";
            block = false;
          }
        ];
      };
      open = {
        rules = [
          # yazi 的 open 规则用 mime(glob)或 url(正则)匹配,不支持 name
          {
            mime = "application/pdf";
            use = [ "zathura" ];
          }
        ];
      };
    };
  };
}
