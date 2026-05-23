{inputs, lib, ...}:
final: prev: import ../pkgs { inherit final lib; pkgs = prev; }