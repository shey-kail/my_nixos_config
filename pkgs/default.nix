{ lib, pkgs }:

{
  krohnkite = pkgs.callPackage ./krohnkite.nix {};
#  gemini-cli = pkgs.callPackage ./gemini-cli {};
}
