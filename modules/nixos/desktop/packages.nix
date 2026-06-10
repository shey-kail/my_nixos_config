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
    # remote desktop
    rustdesk-flutter

    # nix-index
    nix-index

    nix-ld

    firefox

    alacritty

    # file manager(轻量,Qt,LXQt 维护中;走 KIO / gvfs 协议,wayland 原生)
    pcmanfm-qt

    # icon theme(Qogir,扁平化多色,GTK/Qt 应用图标)
    qogir-icon-theme
  ];
}
