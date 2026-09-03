# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个使用 Nix Flakes 的 NixOS 配置仓库,管理一台主机 `wujie`(KDE Plasma 6 桌面环境)。基于 [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config) 的架构,使用 [haumea](https://github.com/nix-community/haumea) 文件系统模块系统按架构 / 主机组织配置。

## 常用命令

通过根目录的 `Makefile` 暴露(默认主机为 `wujie`):

```bash
make rebuild                # sudo nixos-rebuild switch --flake .#wujie
make update                 # sudo nix flake update(所有输入)
make update-nur             # 仅更新 nur 输入
make update-mysecrets       # 仅更新 mysecrets 输入
make update-rebuild         # update 后自动 rebuild
make help                   # 显示帮助
```

格式化与代码检查(dev shell 由 `nix develop` 进入):

```bash
nix fmt                     # alejandra 格式化所有 .nix 文件(formatter 输出)
alejandra .                 # 同上,显式调用
nix build .#checks.x86_64-linux.pre-commit-check  # 跑 alejandra + typos + prettier
```

评估测试:

```bash
nix eval .#evalTests --show-trace --print-build-logs --verbose
```

## 仓库结构(架构概览)

flake 入口链: `flake.nix` → `outputs/default.nix` → `outputs/<arch>/default.nix` → `outputs/<arch>/src/<host>.nix`

```
flake.nix                # 声明 inputs(nixpkgs/unstable、home-manager、plasma-manager、agenix、dms-plugin-registry、mysecrets 等)
outputs/
  default.nix            # 组装所有系统输出:packages / checks / devShells / formatter
  x86_64-linux/
    default.nix          # haumea.lib.load 加载 ./src + ./tests
    src/<host>.nix       # 每台主机一个文件,定义 imports 的 nixos-modules 与 home-modules
    tests/               # eval tests(每台主机可选)
hosts/
  <host>/
    default.nix          # 该主机的 NixOS 顶层配置(hostname、networking、imports 子模块)
    hardware-configuration.nix
    home.nix             # 该主机特有的 home-manager 配置
    remote-desktop/      # 远程桌面相关(可选)
    netdev-mount.nix     # 网络挂载(sshfs/cifs/webdav,目前大多已注释)
modules/
  base.nix               # 公用(同时被 NixOS 与 Darwin 引用)
  nixos/
    base.nix             # NixOS 公用:导入 base/ 与 desktop/
    base/                # nix、networking、ssh、core、packages、user-group、i18n、zram、fcitx5、virtualisation
    base/singbox/        # sing-box 代理服务(含订阅更新 systemd timer)
    base/dae/            # dae 流量控制器(依赖 singbox)
    base/netflow/        # netflow 代理客户端(含 web UI 子模块)
    desktop/             # KDE / Flatpak / 外设 / 安全
home/
  base/                  # 跨平台(core、tui、gui、shells、editors)
  linux/                 # Linux 专用
lib/                     # 工具函数:nixosSystem、scanPaths(自动扫描目录下的 .nix 与子目录)、attrs
pkgs/                    # 自定义包:subpipe(订阅转换器)
overlays/                # nixpkgs 覆盖:自动扫描 ./overlay 下所有 .nix
vars/default.nix         # username、userfullname、useremail、initialHashedPassword
secrets/nixos.nix        # agenix secret 定义(指向 mysecrets 输入中的 .age 文件)
```

### 关键设计点

- **haumea + scanPaths**:`outputs/<arch>/src/<host>.nix` 用 `mylib.nixosSystem` 组装;`modules/nixos/<dir>/default.nix` 通过 `mylib.scanPaths ./.` 自动 import 同级所有 `.nix` 与子目录(忽略 `default.nix`)。新增模块文件无须修改 `default.nix`。
- **specialArgs 注入**:`outputs/default.nix` 的 `genSpecialArgs` 把 `mylib`、`myvars`、`pkgs-unstable`、`pkgs-stable`、`overlays` 注入所有模块,模块参数中可直接使用。
- **overlays**:`overlays/default.nix` 扫描 `overlays/overlay/*.nix`,与 NUR overlay 合并;`overlays/overlay/all-packages.nix` 进一步扫描 `pkgs/` 下的自定义包并 `callPackage`。
- **代理服务依赖链**:`dae` 监听 `singbox.service` / `singbox-backup.service` 之后启动;`singbox` 通过 systemd timer 每 12 小时从订阅 URL 拉取配置(订阅密钥在 `secrets/nixos.nix` 中由 agenix 管理)。
- **预提交钩子**:`outputs/default.nix` 的 `checks.pre-commit-check` 启用 alejandra(Nix 格式化)、typos(拼写)、prettier。其他 deadnix/statix 已注释但工具已在 devShell 中。

### 重要约定

- Nix 格式化使用 `alejandra`,提交前会自动跑。
- `flake.nix` 锁定了 `agenix` 到具体 commit(`4835b1dc`)。`mysecrets` 通过 SSH 走 codeberg。
- `nixpkgs` 走 `nixos-unstable` 分支,`agenix` 的 `nixpkgs` 跟随主 flake。
- 镜像源优先 USTC + 清华(`modules/nixos/base/nix.nix`);允许 unfree,且对部分旧 `nodejs_20` 设置 `permittedInsecurePackages`。
- 用户 SSH 公钥位置在 `modules/nixos/base/core.nix`(目前被注释);默认登录走密码(`initialHashedPassword` 来自 `vars/default.nix`)。
- `myvars.username = "shey"`(注意 hosts 注释里残留 `ryan`,是历史遗留)。
- 添加新主机:见 `hosts/README.md`,要在 `outputs/<arch>/src/` 新建同名 `.nix` 并在 `vars/networking.nix` 加 IP(目前未启用,被注释)。

## 关键模块入口

| 想改的东西                             | 看哪里                                                                                                                 |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| 全局 Nix 设置(GC、镜像源、allowUnfree) | `modules/nixos/base/nix.nix`                                                                                           |
| 主机名 / 网络 / systemd-boot           | `hosts/wujie/default.nix`、`modules/nixos/base/core.nix`                                                               |
| 系统包                                 | `modules/nixos/base/packages.nix`、`modules/nixos/desktop/packages.nix`                                                |
| 用户 / shell / 终端                    | `home/linux/`、`home/base/core/`、`home/base/tui/`                                                                     |
| KDE Plasma 6(默认桌面)                 | `modules/nixos/desktop/kde/` + `plasma-manager` 输入 + `home/linux/gui/base/plasma6/`(dotfiles)                        |
| Hyprland + DMS(备选会话)               | `modules/nixos/desktop/hyprland/`、`modules/nixos/desktop/dms/`(用 nixpkgs `programs.hyprland` / `programs.dms-shell`) |
| 代理订阅 / sing-box                    | `modules/nixos/base/singbox/singbox.nix` + `singbox-templates/`                                                        |
| dae 流量规则                           | `modules/nixos/base/dae/dae.nix` + `dae/config.dae`                                                                    |
| netflow 客户端                         | `modules/nixos/base/netflow/default.nix` + `pkgs/netflow.nix`                                                          |
| 自定义包                               | `pkgs/*.nix`(由 `overlays/overlay/all-packages.nix` 自动 callPackage)                                                  |
| 密钥(agenix)                           | `secrets/nixos.nix`,本体在外部 `mysecrets` 仓库                                                                        |
