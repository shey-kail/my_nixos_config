final: prev:
let
  lib = prev.lib;
  inherit (lib) strings;
  inherit (lib.attrsets) filterAttrs attrNames;
  pkgsDir = toString ../../pkgs;
  isPackage = path: type:
    type == "regular" && strings.hasSuffix ".nix" path;
  packages = attrNames (filterAttrs isPackage (builtins.readDir pkgsDir));
in
lib.foldl' (acc: name:
  acc // { ${strings.removeSuffix ".nix" name} = prev.callPackage (pkgsDir + "/${name}") {}; }
) {} packages