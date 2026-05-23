{inputs, lib, ...}: [
  (import ./r-packages.nix)
  (import ./openldap.nix)
  (import ./pkgs.nix)
]
