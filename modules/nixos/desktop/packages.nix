{
  pkgs,
  lib,
  ...
}:
{
  boot.loader.timeout = lib.mkForce 10; # wait for x seconds to select the boot entry

  environment.systemPackages = with pkgs; [
    wl-clipboard
    xclip

    xeyes

    # video player
    mpv

    # picture shower
    imv

    # pdf viewer
    zathura

    # remote desktop
    rustdesk-flutter

    # nix-index
    nix-index

    nix-ld

    firefox

    alacritty

    # icon theme(Qogir,扁平化多色,GTK/Qt 应用图标)
    qogir-icon-theme
  ];

  services = {
    gvfs.enable = true; # Mount, trash, and other functionalities
    tumbler.enable = true; # Thumbnail support for images
  };

  programs = {
    # dconf is a low-level configuration system.
    dconf.enable = true;

    # thunar file manager(part of xfce) related options
    thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
  };
}
