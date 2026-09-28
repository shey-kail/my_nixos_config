# 山东通安全接入客户端(深信服 aTrust)系统级集成
#
# 应用本体由 pkgs/atrust 重打包(见 pkgs/atrust/default.nix),这里只处理
# 它需要的系统侧东西:
#
#   1) /usr/share/sangfor 兼容软链:aTrust 的 Electron 二进制里硬编码
#      这个路径(找 resources/bin、resources/lib),store 路径塞不回去
#   2) aTrustDaemon 守护进程:接通隧道需要 root,原厂是 systemd 服务
#      (aTrustDaemon.service);这里用 NixOS 声明式写法,ExecStart 直接指向
#      包内脚本(包内脚本已带 LD_LIBRARY_PATH)
#
# 刻意不做(原厂带了但 NixOS 上无法提供,缺了不影响接入转发):
#   - sfuem 内核模块(原包 usr/lib/modules-load.d/sfuem.conf)
#   - sfxs X 模块(原包 etc/X11/xorg.conf.d/20-sfxs.conf,装上会导致 X 起不来)
#   这两项对应终端管控/UEM 类功能。
{
  pkgs,
  lib,
  ...
}: let
  atrust = pkgs.atrust;
  aHome = "${atrust}/share/sangfor/aTrust";
in {
  # 兼容软链(switch 激活时创建,与佳能驱动同一套做法)
  system.activationScripts.atrustUsrBridge = ''
    mkdir -p /usr/share
    ln -sfn ${atrust}/share/sangfor /usr/share/sangfor
  '';

  # 底:开机时也确保存在(普通 L,非 L!)
  systemd.tmpfiles.rules = [
    "d /usr/share 0755 root root -"
    "L /usr/share/sangfor - - - - ${atrust}/share/sangfor"
  ];

  # 安全接入守护进程(隧道/接入需要 root)
  systemd.services.aTrustDaemon = {
    description = "Sangfor aTrust Daemon (山东通安全接入)";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "forking";
      ExecStart = "${atrust}/bin/aTrustDaemon start";
      ExecReload = "${atrust}/bin/aTrustDaemon restart";
      ExecStop = "${atrust}/bin/aTrustDaemon stop";
      PIDFile = "/run/aTrustDaemon.pid";
      Restart = "always";
      RestartSec = "5s";
      KillMode = "process";
      # 原厂 unit 里没有额外沙箱约束,这里保持宽松以兼容其网络/设备操作
      PrivateTmp = false;
    };
  };
}
