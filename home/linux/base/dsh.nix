{
  pkgs,
  myvars,
  ...
}: {
  # DeepSeek Harness Web:用户级 systemd 服务
  #
  # 启动 `dsh --profile web`(profile 定义在 ~/.dsh/profiles/web/
  # cordis.yml + package.json bundles + cordis.patch.yml)。
  #
  # 注意:
  #   - dsh 启动时会写回 profile 目录(prepareProfile 生成 cordis.yml),
  #     所以 DSH_HOME 必须可写;这里直接用用户自己的 ~/.dsh。
  #   - 用户级服务,登录桌面后自动启动(依赖 default.target)。
  #   - webserver 监听 0.0.0.0:3080(由 profile 的 cordis.patch.yml 配置)。
  systemd.user.services.dsh-web = {
    Unit = {
      Description = "DeepSeek Harness Web (dsh --profile web)";
      Documentation = "https://github.com/deepseek-ai/deepseek-harness";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.llm-agents.dsh}/bin/dsh --profile web";

      Environment = [
        "DSH_HOME=/home/${myvars.username}/.dsh"
        "HOME=/home/${myvars.username}"
        # dsh 的工具(terminal/bash、git 等)需要 PATH;systemd 用户服务默认 PATH 很窄
        "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/${myvars.username}/bin:/home/${myvars.username}/.nix-profile/bin"
      ];

      WorkingDirectory = "/home/${myvars.username}";

      Restart = "on-failure";
      RestartSec = "5s";

      # dsh 是常驻 node 进程,给足启动/停止时间
      TimeoutStartSec = 60;
      TimeoutStopSec = 30;

      # 日志进 journal(user 服务:journalctl --user -u dsh-web)
      StandardOutput = "journal";
      StandardError = "journal";
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };
}
