{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.services.hermes-agent;

  # 共享 CLI(single source of truth,跟 shey home 同步)
  sharedCli = import ../../../vars/shared-cli.nix {inherit pkgs;};

  # FHS env:把 hermes-agent + 共享 CLI 全部塞进 FHS targetPkgs。
  # buildFHSEnv 内部构造一个 chroot 风格的 /usr/bin 布局(包含 glibc/gcc/libstdc++/...),
  # 然后通过 runScript 启动 hermes-agent。Python 扩展找不到 .so 的问题
  # 在 FHS 视角下消失,因为 .so 都在 /usr/lib 里。
  #
  # runScript 显式指到 hermes-agent 的 bin(默认是 buildFHSEnv 自身名,会无限循环)。
  fhsEnv = pkgs.buildFHSEnv {
    name = "hermes-agent-fhs";
    # targetPkgs:这些包在 FHS 内部都装到 /usr。
    # cfg.package 自身 + 共享 CLI 都进 FHS。
    targetPkgs = pkgs:
      [
        cfg.package
      ]
      ++ sharedCli;
    # runScript 必须显式指到 hermes 主程序,否则 buildFHSEnv 找不到入口。
    runScript = "${cfg.package}/bin/hermes";
  };

  # 启动命令
  fhsHermesCmd = "${fhsEnv}/bin/hermes-agent-fhs gateway";
in {
  # ============================================================
  # Hermes Agent (Nous Research) — native systemd 模式 + FHS
  #
  # 设计:
  # 1. 不开 container.enable — 走默认 native systemd unit(更轻,无需 docker)
  # 2. user=hermes(默认) — 沙箱最严,服务看不到 shey 的 home/auth
  # 3. CLI 工具走 vars/shared-cli.nix — 加新 CLI 改一处,shey + hermes 同步
  # 4. ExecStart 替换成 buildFHSEnv wrapper — hermes 跑在 FHS 视角的 /usr 布局,
  #    避开 patchelf 后 Python 扩展找不到 .so 的问题
  # 5. 敏感 env(API key)走 agenix → /etc/hermes/env(secrets/nixos.nix 配)
  # 6. addToSystemPackages=true — shey 终端 `hermes` 调本地 CLI(读同 state)
  #
  # 限制:
  # - agent 不能运行时改包(/nix/store 只读 + ProtectSystem=strict)
  # - Python 库需求走 pixi / nix-shell 自管(用户级 venv)
  # - 新 CLI 工具走 shared-cli.nix + git 提交 + rebuild
  # ============================================================
  imports = [
    inputs.hermes-agent.nixosModules.default
  ];

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    # extraPackages 仍写上,这样 hermes 用户 login shell 也能用这些 CLI;
    # FHS 内部走 targetPkgs(下面),service.path 走 fhsEnv。
    extraPackages = sharedCli;
    # TODO: 拿到 OPENROUTER_API_KEY 后取消注。
    # 等 ~/codeberg/mysecrets/hermes/env.age 准备好,把这行加回去:
    #   environmentFiles = [ "/etc/hermes/env" ];
    # 现在没 key,hermes 启动 OK 但首次 LLM 调用会报 no API key。
    restart = "always";
    restartSec = 5;
  };

  # ============================================================
  # hermes 共享工作区:/var/lib/hermes/shared
  # shey 进 hermes group 后能读写(默认只有 hermes 私有)。
  # workspace(/var/lib/hermes/workspace)仍是 hermes 私有中间产物目录,
  # 干净区隔 — agent 草稿不污染 shared。
  # shey ↔ hermes 互通场景:
  #   - hermes 任务产出 report.md → shared/
  #   - shey 扔文件让 hermes 处理 → 放 shared/
  #   - cron / skills 跑任务的产物 → shared/
  # /var/lib 在 rootfs 持久,rebuild 不删,GC 不碰。
  # ============================================================
  users.users.shey.extraGroups = ["hermes"];

  systemd.tmpfiles.rules = [
    "d /var/lib/hermes/shared 2775 hermes hermes - -"
  ];

  # 覆写 module 默认的 ExecStart / path,改成 FHS 包裹版本。
  # 原因:module 默认的 ExecStart 是 ${effectivePackage}/bin/hermes gateway,直接跑
  # patchelf 后的 nix store ELF,会因 Python 扩展找不到 .so 而 fail。
  systemd.services.hermes-agent = {
    serviceConfig.ExecStart = lib.mkForce fhsHermesCmd;
    # 模块默认 path = [ effectivePackage bash coreutils git ] ++ extraPackages,
    # FHS 包裹后这些都不需要,FHS 自己内部有完整 /usr/bin。
    # path 留空 = 不预设 PATH,ExecStart 脚本自己找。
    path = lib.mkForce [];
  };
}
