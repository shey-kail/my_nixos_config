{
  pkgs,
  ...
}: {
  # terminal file manager
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
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
}
