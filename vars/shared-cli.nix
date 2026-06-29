{pkgs}:
# 共享 CLI 工具列表 — single source of truth。
# shey 用户的 home.packages + services.hermes-agent.extraPackages 都从这里 import。
# 加新工具:改这一处,两边同步生效。
#
# 注意:
# - 只放 CLI 工具,不放 GUI 桌面应用(那些走 dms/desktop packages)
# - 不放需要 systemd service / 守护进程的东西(那些走 services.*)
# - 不放 hermes-agent 自己(会循环依赖)
[
  pkgs.fzf
  pkgs.fd
  pkgs.ripgrep
  pkgs.jq
  pkgs.gh
  pkgs.git
  pkgs.bash
  pkgs.coreutils
]
