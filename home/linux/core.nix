{ inputs, pkgs, ... }:
{
  imports = [
    ../base/core
    ../base/home.nix

    ./base
  ];
}
