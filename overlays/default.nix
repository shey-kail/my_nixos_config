{inputs, lib, ...}:
let
  inherit (lib.attrsets) filterAttrs;
  overlayDir = toString ./.;
  isOverlayFile = path: type:
    type == "regular" && path != "default.nix" && lib.strings.hasSuffix ".nix" path;
in
  map (path: import (overlayDir + "/${path}"))
    (builtins.attrNames
      (filterAttrs isOverlayFile
        (builtins.readDir overlayDir)))
