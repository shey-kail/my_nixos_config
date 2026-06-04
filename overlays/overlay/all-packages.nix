final: prev:
let
  inherit (prev) lib;
  scanPkgs = import ../../lib/scanPkgs.nix { inherit lib; };
  pkgsDir = toString ../../pkgs;
in
scanPkgs { inherit pkgsDir; callPackage = prev.callPackage; }
