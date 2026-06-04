{ ... }:
# 纯装配点:所有 netflow 相关资产(包 + 默认配置 + 服务模块 + ui 模块)都在 pkgs/netflow/ 里,
# 这里只 import,不动配置。
{
  imports = [
    ../../../../pkgs/netflow/module.nix
    ../../../../pkgs/netflow/ui-module.nix
  ];
}
