{
  inputs,
  lib,
  ...
}: let
  inherit (lib) strings;
  inherit (lib.attrsets) filterAttrs attrNames;
  overlayDir = ./overlay;
  files = attrNames (
    filterAttrs (path: type: type == "regular" && strings.hasSuffix ".nix" path) (
      builtins.readDir overlayDir
    )
  );

  # 本地手写 overlay:从 overlay/*.nix 自动 import
  localOverlays = map (f: import (toString overlayDir + "/${f}")) files;

  # 第三方 flake overlay:在这里集中登记
  flakeOverlays = [
    inputs.chinese-fonts-overlay.overlays.default
  ];
in
  localOverlays ++ flakeOverlays
