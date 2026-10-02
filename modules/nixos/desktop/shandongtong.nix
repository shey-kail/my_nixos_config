# 山东通安全接入客户端(深信服 aTrust)系统级集成
#
# 应用本体由 pkgs/atrust 重打包(见 pkgs/atrust/default.nix),这里处理它
# 需要的系统侧东西:
#
#   1) /usr/share/sangfor 兼容目录:aTrust 的二进制里硬编码这个路径
#      (找 resources/bin、resources/lib),store 路径塞不回去。
#      注意必须是**真实目录**而不是整棵软链:agent 的单实例锁目录
#      硬编码为 /usr/share/sangfor/.aTrust,写在只读 store 上会导致
#      "Master instance already running" 而启动失败。
#   2) aTrustDaemon 守护进程:隧道需要 root。原厂 aTrustDaemon.sh 有两个
#      问题(ARGS 里的 --plugin-cmd 本版本不识别、末尾裸管道导致 PID 记错),
#      因此直接用包内的前台入口 aTrustAgent + Type=simple 跟踪。
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
in {
  # 兼容目录(switch 激活时创建,与佳能驱动同一套做法)
  system.activationScripts.atrustUsrBridge = ''
    mkdir -p /usr/share
    # 旧版这里做的是整棵树软链,先清掉
    if [ -L /usr/share/sangfor ]; then rm -f /usr/share/sangfor; fi
    mkdir -p /usr/share/sangfor/.aTrust
    chmod 1777 /usr/share/sangfor/.aTrust
    ln -sfn ${atrust}/share/sangfor/aTrust /usr/share/sangfor/aTrust
  '';

  # 兜底:开机时也确保存在(普通 L,非 L!)
  systemd.tmpfiles.rules = [
    "d /usr/share 0755 root root -"
    "d /usr/share/sangfor 0755 root root -"
    "d /usr/share/sangfor/.aTrust 1777 root root -"
    "L /usr/share/sangfor/aTrust - - - - ${atrust}/share/sangfor/aTrust"
  ];

  # 安全接入守护进程(隧道/接入需要 root)
  systemd.services.aTrustDaemon = {
    description = "Sangfor aTrust Daemon (山东通安全接入)";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    # agent 内部用 shell 调这些工具来识别当前登录用户/会话:
    #   loginctl ... | awk ... | xargs loginctl show-session | grep ...
    #   getent passwd | awk -F ':' ...
    #   ps -eo pid,command | grep -w ...
    # 缺了会报 "getent/awk: 未找到命令",影响它判断用户与建立隧道
    path = with pkgs; [
      gawk
      glibc.bin # getent
      procps # ps
      coreutils
      gnugrep
      findutils
      systemd # loginctl
    ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${atrust}/bin/aTrustAgent";
      # 原厂是 Restart=always,但 agent 正常退出时会被无限拉起;
      # 只在异常退出时重启
      Restart = "on-failure";
      RestartSec = "5s";
      # 原厂 unit 里没有额外沙箱约束,这里保持宽松以兼容其网络/设备操作
      PrivateTmp = false;
    };
  };
}
