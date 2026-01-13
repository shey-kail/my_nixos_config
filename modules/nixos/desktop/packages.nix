{
  pkgs,
  lib,
  ...
}: {
  boot.loader.timeout = lib.mkForce 10; # wait for x seconds to select the boot entry

  environment.systemPackages = with pkgs; [
    wl-clipboard
    xclip

    xorg.xeyes

    # singbox gui
    # throne

    # video player
    mpv
    # remote desktop
    rustdesk-flutter

    # nix-index
    nix-index

    nix-ld

    microsoft-edge
    firefox
  ];
  programs.throne = {
    enable = true;
    tunMode = {
      enable = true;
      setuid = true;
    };
  };
}
