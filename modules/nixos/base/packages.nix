{pkgs, overlays, ...}: {
  # Apply NUR overlay
  nixpkgs.overlays = overlays;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # system tools
    psmisc # killall/pstree/prtstat/fuser/...
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb
    hdparm # for disk performance, command
    dmidecode # a tool that reads information about your system's hardware from the BIOS according to the SMBIOS/DMI standard
    parted

    # backup
    bup
    rclone

    # aircrack-ng
    aircrack-ng

    #vainfo
    libva-utils.out

    radeontop

    distrobox
    crun
  ];

}
