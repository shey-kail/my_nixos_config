{
  pkgs,
  lib,
  ...
}: let
  hostName = "wujie"; # Define your hostname.
  # OpenViking ov.conf 模板(nix store 里,不含真 key;启动时 sed 替换占位符)
  ovConfTemplate = pkgs.writeText "openviking-ov.conf" ''
    {
      "vlm": {
        "provider": "volcengine",
        "api_key": "__DOUBAO_API_KEY__",
        "model": "doubao-seed-2-0-lite-260428",
        "api_base": "https://ark.cn-beijing.volces.com/api/v3",
        "temperature": 0.1,
        "max_retries": 3
      },
      "embedding": {
        "dense": {
          "provider": "volcengine",
          "api_key": "__DOUBAO_API_KEY__",
          "model": "doubao-embedding-vision-251215",
          "api_base": "https://ark.cn-beijing.volces.com/api/v3",
          "dimension": 1024,
          "input": "multimodal"
        }
      }
    }
  '';
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
  #   - embedding / VLM 接火山方舟;API key 走 agenix(不落 nix store)
  #   - 模块 preStart 的 chown 在 CapabilityBoundingSet= 下会失败(无 CAP_CHOWN),
  #     这里用 tmpfiles 预建目录+属主,并覆盖 ExecStartPre 绕过。
  systemd.tmpfiles.rules = [
    "d /var/lib/openviking 0755 shey users -"
  ];
  # 覆盖模块生成的 pre-start(chown 脚本),改为不做事(目录已由 tmpfiles 建好)
  systemd.services.openviking.serviceConfig.ExecStartPre = lib.mkForce [];

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
    # settings 保持 null:ov.conf 由下方 systemd 动态生成
    # (module 的 configFile=null 时,服务默认读 ${dataDir}/ov.conf)
  };

  # 在 openviking 启动前,用 agenix 解密好的 API key 生成 ov.conf
  # (避免 key 明文进 nix store;运行时读 /run/agenix/doubao_embedding_api)
  systemd.services.openviking-config = {
    description = "Generate OpenViking ov.conf from agenix secrets";
    before = ["openviking.service"];
    requiredBy = ["openviking.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      KEY="$(cat /run/agenix/doubao_embedding_api)"
      mkdir -p /var/lib/openviking
      # 用 nix 生成的 JSON 模板(不含 key),运行时把占位符替换为 agenix key
      sed "s|__DOUBAO_API_KEY__|$KEY|g" ${ovConfTemplate} > /var/lib/openviking/ov.conf
      chown shey:users /var/lib/openviking/ov.conf
      chmod 600 /var/lib/openviking/ov.conf
    '';
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
