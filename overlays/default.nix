{inputs, lib, ...}:
let
  inherit (lib) strings;
  inherit (lib.attrsets) filterAttrs attrNames;
  overlayPath = ./.;
  isOverlayFile = path: type:
    type == "regular" && path != "default.nix" && strings.hasSuffix ".nix" path;
in
  map (path: import (overlayPath + "/${path}"))
    (attrNames (filterAttrs isOverlayFile (builtins.readDir overlayPath)))