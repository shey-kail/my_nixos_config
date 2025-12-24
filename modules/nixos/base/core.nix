{lib, ...}: {
  boot.loader.systemd-boot = {
    enable = true;
    # we use Git for version control, so we don't need to keep too many generations.
    configurationLimit = lib.mkDefault 10;
    # pick the highest resolution for systemd-boot's console.
    consoleMode = lib.mkDefault "max";
  };
  

  boot.kernel.features.userNamespace.enable = true;

  boot.loader.timeout = lib.mkDefault 8; # wait for x seconds to select the boot entry

  # for power management
  services = {
    power-profiles-daemon = {
      enable = true;
    };
    upower.enable = true;
  };
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;
}
