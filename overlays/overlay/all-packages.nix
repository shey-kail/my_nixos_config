final: prev:
let
  inherit (final.lib) strings;
  inherit (final.lib.attrsets) filterAttrs attrNames;
  pkgsDir = toString ../pkgs;
  isPackage = path: type:
    type == "regular" && strings.hasSuffix ".nix" path;
  packages = attrNames (filterAttrs isPackage (builtins.readDir pkgsDir));
in
builtins.listToAttrs (
  map (name: {
    inherit name;
    value = prev.callPackage (pkgsDir + "/${name}") {};
  }) packages
)