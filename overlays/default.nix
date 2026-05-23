{inputs, lib, ...}: [
  (import ./r-packages.nix)
  (import ./openldap.nix)
  (final: prev: import ../pkgs { inherit lib; pkgs = prev; })
]
