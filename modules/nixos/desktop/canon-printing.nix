# 佳能 UFR II 驱动在 NixOS 上的运行桥接
#
# 佳能二进制把绝对路径写死,store 路径塞不回去:
#   - rastertoufr2 滤镜内部 execv("/usr/bin/cnrsdrvufr2")
#   - cnrsdrvufr2 读取 "/usr/share/caepcm"(色彩数据)与
#     "/etc/cngplp2/options/options.conf"
#
# 两种机制覆盖:
#   1) system.activationScripts:每次 nixos-rebuild switch 激活时以
#      root 创建软链(NixOS 官方建 /usr/bin/env 的同款机制),立即生效;
#   2) systemd.tmpfiles 普通 L 规则:开机时再兜底刷新(注意不能用 L!,
#      L! 只在开机阶段执行,手动 systemd-tmpfiles --create 会忽略)。
{
  pkgs,
  lib,
  ...
}: let
  canon = pkgs.canon-ufr2;
in {
  # 佳能 UFR II 驱动挂进 CUPS:PPD + 滤镜(rastertoufr2/pdftocpca)+ USB 后端
  services.printing.drivers = [canon];

  # 主机制:switch 激活时立刻建软链
  system.activationScripts.canonUfr2Bridge = lib.mkAfter ["usrbinenv"] ''
    mkdir -p /usr/bin /usr/share
    ln -sfn ${canon}/bin/cnrsdrvufr2 /usr/bin/cnrsdrvufr2
    ln -sfn ${canon}/share/caepcm /usr/share/caepcm
    mkdir -p /etc/cngplp2/options /etc/cngplp2/account
  '';

  # 兜底:开机时也确保软链存在(普通 L,非 L!)
  systemd.tmpfiles.rules = [
    "d /usr 0755 root root -"
    "d /usr/bin 0755 root root -"
    "d /usr/share 0755 root root -"
    "L /usr/bin/cnrsdrvufr2 - - - - ${canon}/bin/cnrsdrvufr2"
    "L /usr/share/caepcm - - - - ${canon}/share/caepcm"
    "d /etc/cngplp2/options 0755 root root -"
    "d /etc/cngplp2/account 0755 root root -"
  ];
}