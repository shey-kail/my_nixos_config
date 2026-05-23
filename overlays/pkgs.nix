{inputs, lib, ...}:
final: prev: {
  subpipe = prev.callPackage ../pkgs/subpipe.nix {};
}