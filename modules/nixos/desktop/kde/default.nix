{
  pkgs,
  ...
}:
{

  #imports = mylib.scanPaths ./.;

  # enable kde connect
  programs.kdeconnect.enable = true;

  environment = {
#    systemPackages = (builtins.attrValues {
#      inherit (pkgs)
#        kde-rounded-corners;
#        # klassy;
#    });
    plasma6.excludePackages = builtins.attrValues {
      inherit (pkgs.kdePackages)
        elisa kate krunner baloo;
    };
  };
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland = {
        enable = true;
        compositor = "kwin";
      };
    };
    xserver = {
      enable = true;
      excludePackages = [ pkgs.xterm ];
    };
  };

  networking.firewall = rec {
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };
}
