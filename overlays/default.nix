{inputs, lib, ...}:
let
  inherit (lib) strings;
  inherit (lib.attrsets) filterAttrs attrNames;
  overlayDir = ./overlay;
  files = attrNames (filterAttrs (path: type:
    type == "regular" && strings.hasSuffix ".nix" path
  ) (builtins.readDir overlayDir));
in
  map (f: import (toString overlayDir + "/${f}")) files