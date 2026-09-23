# 佳能 UFR II 驱动在 NixOS 上的运行桥接
#
# 佳能二进制把绝对路径写死,store 路径塞不回去:
#   - rastertoufr2 滤镜内部 execv("/usr/bin/cnrsdrvufr2")
#   - cnrsdrvufr2 读取 "/usr/share/caepcm"(色彩数据)与
#     "/etc/cngplp2/options/options.conf"
# 用 systemd.tmpfiles 把这些路径链到 store 里的驱动包,
# 让 CUPS 跑滤镜时能找到渲染核心。打印主链路不再依赖
# 认证/GTK 设置程序,是纯本地光栅->UFR II 转换。
{
  pkgs,
  lib,
  ...
}: let
  canon = pkgs.canon-ufr2;
in {
  # 佳能 UFR II 驱动挂进 CUPS:PPD + 滤镜(rastertoufr2/pdftocpca)+ USB 后端
  services.printing.drivers = [canon];

  # 兼容链接(开机时由 systemd-tmpfiles 创建,root 属主)
  systemd.tmpfiles.rules = [
    # /usr 目录骨架
    "d /usr 0755 root root -"
    "d /usr/bin 0755 root root -"
    "d /usr/share 0755 root root -"
    # 渲染核心:rastertoufr2 硬编码 execv 的路径
    "L! /usr/bin/cnrsdrvufr2 - - - - ${canon}/bin/cnrsdrvufr2"
    # 色彩管理数据:cnrsdrvufr2 运行时读取
    "L! /usr/share/caepcm - - - - ${canon}/share/caepcm"
    # 驱动选项目录(空即可,缺失也能跑)
    "d /etc/cngplp2/options 0755 root root -"
    "d /etc/cngplp2/account 0755 root root -"
  ];
}