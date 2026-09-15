{...}: let
  hostName = "wujie"; # Define your hostname.
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # Include tailscale and sunshine.
    ./remote-desktop/default.nix
    # OpenViking 的 nixosModule 在 outputs/x86_64-linux/src/wujie.nix 里 import
    # (那里有 haumea 注入的 inputs;模块内引用 inputs 会导致 infinite recursion)
  ];

  # OpenViking 服务:本地 127.0.0.1:1933,数据放 /var/lib/openviking
  # 说明:
  #   - 用 shey 用户跑,方便索引 ~/Codes 下的仓库(默认 openviking 用户受 ProtectHome 限制)
  #   - embedding / VLM 端点稍后通过 settings 或 configFile 补(viking 需要两个模型服务)
  services.openviking = {
    enable = true;
    user = "shey";
    group = "users";
    port = 1933;
    host = "127.0.0.1";
    dataDir = "/var/lib/openviking";
    readOnlyPaths = [
      "/home/shey/Codes"
    ];
  };

  networking = {
    inherit hostName;
    # desktop need its cli for status bar
    networkmanager.enable = true;
  };

  # 代理服务存在但默认不自动启动(dae / singbox / singbox-backup / 订阅更新 timer)
  # 需要时手动启动:
  #   sudo systemctl start singbox-sub-update.service   # 先拉取订阅
  #   sudo systemctl start singbox                      # 主订阅
  #   sudo systemctl start dae                           # dae 流量控制(依赖 singbox)
  # 若要开机自启:
  #   modules/nixos/base/dae/dae.nix:把 systemd.services.dae.wantedBy 改回 [ "multi-user.target" ]
  #   modules/nixos/base/singbox/singbox.nix:恢复 singbox/singbox-backup 的 wantedBy

  # kmscon 字体大小按本机分辨率调(wujie:2K / 2560×1440)。
  # 改这个值不需要动 modules/nixos/desktop/fonts.nix。
  services.kmscon.config.font-size = 24;

  # conflict with feature: containerd-snapshotter
  # virtualisation.docker.storageDriver = "btrfs";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
