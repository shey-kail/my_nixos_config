{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    # Misc
    gnupg
    gnumake

    # Interactively filter its input using fuzzy searching, not limit to filenames.
    fzf
    # search for files by name, faster than find
    fd

    csvtk

    lazygit # Git terminal UI.
    gping # ping, but with a graph(TUI)
    resvg # preview svg, required by yazi
    wl-clipboard # clipboard, required by yazi
    zoxide #for historical directories navigation, requires fzf, required by yazi
  ];

  programs = {
    # A command-line fuzzy finder
    fzf = {
      enable = true;
      # https://github.com/catppuccin/fzf
      # catppuccin-mocha
      colors = {
        "bg+" = "#313244";
        "bg" = "#1e1e2e";
        "spinner" = "#f5e0dc";
        "hl" = "#f38ba8";
        "fg" = "#cdd6f4";
        "header" = "#f38ba8";
        "info" = "#cba6f7";
        "pointer" = "#f5e0dc";
        "marker" = "#f5e0dc";
        "fg+" = "#cdd6f4";
        "prompt" = "#cba6f7";
        "hl+" = "#f38ba8";
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
