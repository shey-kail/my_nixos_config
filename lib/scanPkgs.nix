{ lib }:
{ pkgsDir, callPackage }:
let
  inherit (lib) strings;
  inherit (lib.attrsets) filterAttrs attrNames;
  entries = builtins.readDir pkgsDir;

  # pkgs/<name>.nix(扁平)
  flatPkgs = attrNames (filterAttrs (name: type: type == "regular" && strings.hasSuffix ".nix" name) entries);

  # pkgs/<dir>/default.nix(子目录)
  subdirs = attrNames (filterAttrs (n: type: type == "directory" && builtins.pathExists (pkgsDir + "/${n}/default.nix")) entries);

  # 命名空间互不冲突:扁平列表里都是 *.nix,子目录列表里都是无后缀目录名
  toPath = name:
    if strings.hasSuffix ".nix" name
    then (pkgsDir + "/${name}")
    else (pkgsDir + "/${name}/default.nix");
  toName = name:
    if strings.hasSuffix ".nix" name
    then (strings.removeSuffix ".nix" name)
    else name;
in
lib.foldl' (acc: name:
  acc // { ${toName name} = callPackage (toPath name) {}; }
) {} (flatPkgs ++ subdirs)
