{ pkgs, ... }:
{
  home.packages = with pkgs; [
    xarchiver
    wpsoffice-cn
  ];
}
