{ lib, pkgs }:

{
  krohnkite = pkgs.callPackage ./krohnkite.nix {};
  subpipe = pkgs.callPackage ./subpipe.nix {};
}
