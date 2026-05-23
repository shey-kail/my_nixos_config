{inputs, lib, ...}:
let
  inherit (lib) strings;
  inherit (lib.attrsets) filterAttrs attrNames;
  overlayDir = ./overlay;
  isOverlayFile = path: type:
    type == "regular" && strings.hasSuffix ".nix" path;
  files = attrNames (filterAttrs isOverlayFile (builtins.readDir overlayDir));
in
  map (f: import (overlayDir + "/${f}")) files