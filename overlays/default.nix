{inputs, lib, ...}:
let
  overlayPath = ./.;
  isOverlayFile = path: type:
    type == "regular" && path != "default.nix" && lib.strings.hasSuffix ".nix" path;
in
  map (path: import (overlayPath + "/${path}"))
    (builtins.attrNames (lib.attrsets.filterAttrs isOverlayFile (builtins.readDir overlayPath)))