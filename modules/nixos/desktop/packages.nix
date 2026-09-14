{
  pkgs,
  lib,
  ...
}: {
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

    # icon theme(Qogir,扁平化多色,GTK/Qt 应用图标)
    qogir-icon-theme

    # 浩辰CAD 2027(Kylin deb 重打包,免 senseshield 锁)
    gstar-cad
  ];
}
