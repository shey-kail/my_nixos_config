{
  lib,
  ...
}: {
  # to install chrome, you need to enable unfree packages
  nixpkgs.config.allowUnfree = lib.mkForce true;
  #nixpkgs.config.allowUnsupportedSystem = lib.mkForce true;

  # Allow insecure nodejs for backward compatibility
  nixpkgs.config.permittedInsecurePackages = [
    "nodejs-20.20.2"
    "nodejs-slim-20.20.2"
    "nodejs-20.19.1"
    "nodejs_20"
    "nodejs-20.20.2-source"
  ];

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  # Manual optimise storage: nix-store --optimise
  # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
  nix.settings.auto-optimise-store = true;

  nix.channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead.
}
