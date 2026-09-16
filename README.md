# Shey's Nix Config

管理一台主机 `wujie`(KDE Plasma 6 桌面,`x86_64-linux`)的 NixOS + Home-Manager 配置。
架构基于 [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config),使用 [haumea](https://github.com/nix-community/haumea) 按架构 / 主机组织模块。

> 想深入学 Nix 语法与 Flakes 机制?推荐 [NixOS & Flakes Book](https://github.com/ryan4yin/nixos-and-flakes-book)。

---

## 一、Flake 入口链

```
flake.nix
 └─ outputs/default.nix
     └─ outputs/x86_64-linux/default.nix    (haumea.lib.load ./src)
         └─ outputs/x86_64-linux/src/wujie.nix
             └─ mylib.nixosSystem (lib/nixosSystem.nix)
                 └─ nixpkgs.lib.nixosSystem
```

加新主机:在 `outputs/x86_64-linux/src/<name>.nix` 新建一个文件,haumea 自动加载。

### 关键设计点

- **haumea** 把 `src/<host>.nix` 作为函数执行,返回 `nixosConfigurations` / `packages`,再 merge 到 flake outputs。
- **specialArgs 注入**(`outputs/default.nix` 的 `genSpecialArgs`):`mylib`、`myvars`、`pkgs-unstable`、`pkgs-stable`、`overlays`、`inputs` 全部传给所有模块。
- **scanPaths 自动导入**:每个目录的 `default.nix` 用 `imports = mylib.scanPaths ./.;` 把同级的 `.nix` 文件和子目录自动 import,**新增模块文件无须改 `default.nix`**。

---

## 二、Flake Inputs

| input                 | 用途                                                                |
| --------------------- | ------------------------------------------------------------------- |
| `nixpkgs`             | `nixos-unstable` 分支                                               |
| `home-manager`        | 用户级配置(`nixpkgs` 跟随主 flake)                                  |
| `dms-plugin-registry` | DankMaterialShell 插件注册表                                        |
| `nix-flatpak`         | Flatpak 服务模块                                                    |
| `nur`                 | NUR overlay                                                         |
| `nix-gaming`          | 游戏相关 overlay                                                    |
| `haumea`              | v0.2.2 文件系统模块加载器                                           |
| `agenix`              | **锁死 commit `4835b1dc`(2025-05-18)**,用 ryantm/agenix             |
| `pre-commit-hooks`    | cachix/pre-commit-hooks.nix                                         |
| `mysecrets`           | `git+ssh://git@codeberg.org/sheykail/mysecrets.git`,`flake = false` |

---

## 三、Outputs(`outputs/default.nix`)

| output                             | 内容                                                                      |
| ---------------------------------- | ------------------------------------------------------------------------- |
| `nixosConfigurations`              | 每台主机的系统配置(目前只有 `wujie`)                                      |
| `packages`                         | haumea `src/*/packages` 合并 + 自动扫描 `pkgs/` 目录的 callPackage        |
| `evalTests`                        | 单元测试断言(空 = 通过)                                                   |
| `checks.<system>.pre-commit-check` | alejandra + typos + prettier                                              |
| `devShells.default`                | `alejandra / deadnix / statix / typos / prettier / gcc / bashInteractive` |
| `formatter`                        | `alejandra`                                                               |

---

## 四、模块系统:haumea + scanPaths

### haumea 怎么用

`outputs/x86_64-linux/default.nix:9`:

```nix
data = haumea.lib.load {
  src = ./src;
  inputs = args;
};
```

把 `src/<host>.nix` 的内容当函数执行,返回的 attrset 合并为 `nixosConfigurations` / `packages`。`loadEvalTests` 同理处理 `./tests`。

### scanPaths 自动导入(`lib/default.nix:19`)

```nix
scanPaths = path:
  builtins.map (f: path + "/${f}")
  (attrNames (filterAttrs (n: t:
    t == "directory" || (n != "default.nix" && hasSuffix ".nix" n))
    (readDir path)));
```

应用点(全部 `imports = mylib.scanPaths ./.;`):

| 路径                           | 扫出的内容                                                                                                                       |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| `modules/nixos/base/`          | core / nix / networking / ssh / packages / user-group / i18n / zram / fcitx5 / virtualisation + 子目录 `singbox / dae / netflow` |
| `modules/nixos/desktop/`       | kde / flatpak / fhs / fonts / peripherals / security / packages                                                                  |
| `home/base/{core, tui, gui}/`  | 跨平台 home 配置                                                                                                                 |
| `home/linux/{base, gui/base}/` | Linux 专用 home 配置                                                                                                             |

`pkgs/netflow/` 例外:手动 `imports = [ ./module.nix ./ui-module.nix ]`(需要严格控制导入顺序)。

---

## 五、Hosts

`hosts/wujie/default.nix` 只做四件事:

1. **imports**:`./netdev-mount.nix`(目前全注释)、`./hardware-configuration.nix`、`./remote-desktop/`
2. **networking**:`hostName = "wujie"`,`networkmanager.enable = true`(KDE 状态栏需要 nmcli)
3. **代理四件套开关**:
   ```nix
   services.dae.enable = true;
   services.netflow.enable = true;
   services.netflow-ui.enable = true;
   ```
   (singbox / singbox-backup 在 `modules/nixos/base/singbox/singbox.nix` 里**硬编码** `wantedBy=multi-user.target`,默认启用)
4. `system.stateVersion = "24.11"`

`hosts/wujie/home.nix`:仅配置 `programs.ssh`(`enableDefaultConfig = false` + `identitiesOnly = true`)。

### `hosts/wujie/remote-desktop/`

- `tailscale.nix`:`tailscale.service` + `tailscale-autoconnect.service`(oneshot,自动 `tailscale up`)
- `sunshine.nix`:**整段被注释**(自建 game stream),保留供以后启用
- `default.nix`:装 `waypipe`(Wayland 转发) + `moonlight-qt` 客户端

---

## 六、代理服务依赖链

```
   ┌─ singbox.service       (systemd, modules/nixos/base/singbox/singbox.nix)
   ├─ singbox-backup.service
   ├─ netflow.service       (pkgs/netflow/module.nix)
   └─ netflow-ui.service    (pkgs/netflow/ui-module.nix)
                       │
               dae.service (after + wants 上面三个)
```

- **sing-box**:`singbox.nix` + `singbox-update.sh`(systemd timer 每 12h 拉订阅)+ `singbox-templates/` 模板
- **dae**(流量分流器):监听 12345/tcp,`configFile = ./config.dae` 走全局 DNS + 节点池。**dae 自己负责 DNS 解析和流量分流,singbox/netflow 只作为节点池**
- **netflow**(青云梯客户端,`pkgs/netflow/`):自行打包,带 `module.nix`(服务) + `ui-module.nix`(Web UI) + `default.nix`(包) + `restore/v2board/`(订阅恢复脚本) + `ui/app.py`(Flask UI)
- 三个上游**互斥**,dae 同时 wants 三个,daemon 化后 `dae` 接管所有流量分流

---

## 七、自定义包(`pkgs/`)

| 包        | 用途       |
| --------- | ---------- |
| `subpipe` | 订阅转换器 |

扫描机制 `lib/scanPkgs.nix` 同时支持:

- `pkgs/<name>.nix`(扁平,文件名作 attr 名)
- `pkgs/<dir>/default.nix`(子目录,目录名作 attr 名)

---

## 八、Overlay 链

```
NUR overlay
   ↓
overlays/overlay/*.nix            (自动扫 openldap.nix / r-packages.nix)
   ↓
overlays/overlay/all-packages.nix (再扫一遍 pkgs/ 走 callPackage)
   ↓
最终 overlays 数组 ──→ pkgs.overlays ──→ 所有模块可用
```

---

## 九、Secrets 管理(agenix)

`secrets/nixos.nix`:

- 加密身份:`age.identityPaths = [ /etc/ssh/ssh_host_ed25519_key /home/shey/.ssh/id_rsa ]`(主机私钥 + 用户私钥均可解密)
- 三类权限预设:`high_security`(root 0600)/ `user_readable`(用户 0500)/ `normal`(用户 0600)
- 当前解密的密钥:
  - `wujie_private` → `/etc/ssh/ssh_host_ed25519_key`
  - `shey_private` → `/home/shey/.ssh/id_rsa`
  - `shey_rclone` → `~/.config/rclone/rclone.conf`
  - `subscriptions_main` / `subscriptions_backup` → sing-box 订阅
- `environment.etc."ssh/ssh_host_ed25519_key".source` 把解密结果再放到 `/etc/`

---

## 十、Home-Manager

`outputs/x86_64-linux/src/wujie.nix` 给 `home-modules` 注入:

- `home/linux/gui.nix`(cross-OS + Linux 通用聚合点)
- `hosts/wujie/home.nix`(主机特有)

`home/linux/gui.nix` 聚合:

- `home/base/{core, tui, gui, home.nix}`(跨平台)
- `home/linux/{base, gui}`(Linux 专用)
- `home/linux/gui/base/fcitx5`(桌面输入法)
- `home/linux/gui/base/sunshine`(Sunshine 客户端,目前注释)
- `home/linux/gui/base/xdg.nix`(MIME 默认应用)
- `home/linux/base/{shell, tools, net_mount}.nix`

---

## 十一、关键设计取舍

| 设计                         | 取舍                                                          |
| ---------------------------- | ------------------------------------------------------------- |
| 走 `nixos-unstable`          | 拿最新包,代价是偶发回归                                       |
| `agenix` 锁 commit           | 不被上游 breaking 变化影响                                    |
| `pkgs-stable` 在 specialArgs | 留作模块内 `pkgs-stable.<pkg>` 拿稳定版兜底                   |
| `dae` 硬依赖代理服务         | 想关闭所有代理得手动 `disable` dae 引用                       |
| `singbox` wantedBy 硬编码    | 与 `dae` 解耦困难,改用建议在 `singbox.nix` 里加 `enable` 选项 |
| 镜像走 USTC + 清华           | `modules/nixos/base/nix.nix` 里 `substituters` 配置           |
| `mysecrets` 走 SSH+codeberg  | 网络受限环境会卡 `nix flake update`                           |

---

## 十二、修改工作的对应位置速查

| 想改什么                     | 看哪里                                                                          |
| ---------------------------- | ------------------------------------------------------------------------------- |
| 全局 Nix 镜像/GC/allowUnfree | `modules/nixos/base/nix.nix`                                                    |
| 主机名/IP/systemd-boot       | `hosts/wujie/default.nix` + `hardware-configuration.nix`                        |
| 系统级包                     | `modules/nixos/{base,desktop}/packages.nix`                                     |
| 用户级 GUI                   | `home/linux/gui/base/`                                                          |
| KDE Plasma                   | `modules/nixos/desktop/kde/` + `home/linux/gui/base/plasma6/`                   |
| KDE 桌面主题 / Win11 外观     | `home/linux/gui/base/plasma6/themes/`(数据主题)+ `dotfiles_writable/`(~/.config 快照)+ `default.nix` 的 `ensure*` rsync 段 |
| KVM 虚拟机(win10)            | `modules/nixos/base/virtualisation.nix`(固件自动修复 + vm-backup + vm-restore) |
| sing-box 订阅/模板           | `modules/nixos/base/singbox/singbox.nix` + `singbox-templates/`                 |
| dae 流量规则                 | `modules/nixos/base/dae/dae.nix` + `config.dae`                                 |
| netflow 客户端               | `modules/nixos/base/netflow/default.nix` → `pkgs/netflow/`                      |
| 新主机                       | `outputs/x86_64-linux/src/<name>.nix` + `hosts/<name>/` + `vars/networking.nix` |
| 新系统模块                   | 丢到 `modules/nixos/{base,desktop}/` 任意目录,`scanPaths` 自动捡                |
| 密钥                         | `secrets/nixos.nix` + 外部 `mysecrets` 仓库的 `.age` 文件                       |

---

## 十三、已知小坑

- `outputs/default.nix:30` 引用 `inputs.nixpkgs-stable`,但 `flake.nix` 没声明这个 input —— 需要补 `nixpkgs-stable.url`
- `hosts/wujie/remote-desktop/sunshine.nix` 整段注释
- `hosts/wujie/netdev-mount.nix` 几乎全注释
- `overlays/overlay/openldap.nix` / `r-packages.nix` 体积很小(112 / 313 字节),可能是空 stub
- `pkgs/netflow/restore/v2board/` 子目录目前是历史遗留
- netflow 4 个 OSS 订阅 URL 已死(wrapper 脚本能跑、UCI 读取已通过 strace 验证,登录断在订阅环节)

---

## 十四、KVM 虚拟机(win10)备份与还原

本机唯一 KVM 虚拟机是 `win10`(UEFI + Secure Boot 关闭 + virtiofs 共享 `linux` 文件夹)。

### 背景:为什么 NixOS 更新会弄坏 VM

NixOS 每次 `nixos-rebuild` 后,QEMU/OVMF 固件在 nix store 里的路径会变
(`/nix/store/<hash>-qemu-*/share/qemu/edk2-*.fd`)。如果 VM 的 XML 里写死了
这种带 hash 的路径,rebuild 后旧路径被 GC 删除 → libvirt 报"不支持 EFI"。

**解决办法已在模块里固化**:

| systemd 服务 | 作用 | 触发 |
|---|---|---|
| `libvirt-fix-efi-firmware` | 把 XML 里 nix store 固件路径统一切到稳定路径 `/run/libvirt/nix-ovmf/*` | 开机自动(幂等) |
| `vm-backup` | 把 VM 文件(dqcow2 磁盘 + XML + NVRAM)rclone 同步到 123 云盘 WebDAV | **手动** |
| `vm-restore` | VM 文件缺失时从 WebDAV 拉回并 `virsh define` | 开机自动(幂等) |
| `rclone-webdav`(既有) | 自动挂载 123 云盘到 `~/Projects/webdav123` | 登录自动 |

### 日常操作

```bash
# 备份前先关机(运行中的 qcow2 备份不一致)
sudo virsh shutdown win10

# 手动备份到云盘(123pan,明文,增量同步)
sudo systemctl start vm-backup

# 查看备份结果
sudo systemctl status vm-backup
rclone ls webdav_123:/webdav/wujie/vm-backup/images/

# 启动 VM
sudo virsh start win10
```

备份目标:`webdav_123:/webdav/wujie/vm-backup/`(123 云盘)
备份内容:`images/win10.qcow2`(~10G)· `qemu/win10.xml` · `nvram/win10_VARS.fd`

### 新设备重装后自动还原(正常流程)

```bash
git clone <本仓库> && cd nixos
make rebuild     # 或 sudo nixos-rebuild switch --flake .#wujie
```

rebuild 完成后,下面三件事自动发生,不需要手工:

1. `rclone-webdav` 挂载云盘(需登录桌面会话;若调 `systemctl --user start rclone-webdav` 可提前)
2. `vm-restore` 检测到 `/var/lib/libvirt/images/win10.qcow2` 不存在 → 从云盘拉回
   `qcow2 + XML + NVRAM`,并 `virsh define`
3. `libvirt-fix-efi-firmware` 兜底修正固件路径

等磁盘拉完(10G,看 `journalctl -u vm-restore -f`)后:

```bash
sudo virsh start win10
```

### 自动还原失败时的手动步骤

如果 `vm-restore` 因网络/云盘故障没拉成,或想完全手动:

```bash
# 1. 挂载云盘(等价于 rclone-webdav 服务)
rclone mount webdav_123:/webdav/ ~/Projects/webdav123 --vfs-cache-mode full &
#   或直接对 remote 路径操作(不挂载):
RCLONE_CONFIG=/home/shey/.config/rclone/rclone.conf

# 2. 确认云盘上有备份
rclone --config $RCLONE_CONFIG ls webdav_123:/webdav/wujie/vm-backup/

# 3. 手动拉回文件
sudo rclone --config $RCLONE_CONFIG copy \
  webdav_123:/webdav/wujie/vm-backup/images/ /var/lib/libvirt/images/
sudo rclone --config $RCLONE_CONFIG copy \
  webdav_123:/webdav/wujie/vm-backup/qemu/ /var/lib/libvirt/qemu/
sudo mkdir -p /var/lib/libvirt/qemu/nvram
sudo rclone --config $RCLONE_CONFIG copy \
  webdav_123:/webdav/wujie/vm-backup/nvram/ /var/lib/libvirt/qemu/nvram/

# 4. 重新定义域
sudo virsh define /var/lib/libvirt/qemu/win10.xml

# 5. 固件路径自动修复(或手动确认 loader 用的是稳定路径)
sudo systemctl start libvirt-fix-efi-firmware

# 6. 启动
sudo virsh start win10
```

### 注意事项

- 备份是**明文**(未加密),云盘账号即备份安全性,请保管好 123pan 凭据
- 云盘容量充足(1.0P),10G 的 qcow2 不是问题
- VM 运行时不要备份(会得到不一致快照)
- 新增第二台 VM:在 `virtualisation.nix` 的 `vm-restore` 里把磁盘名加进 `RESTORE_DISKS`,并在 `vm-backup` 里补对应 copy 行

---

## 十五、常用命令

通过根目录 `Makefile` 暴露(默认主机 `wujie`):

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
nix fmt                     # alejandra 格式化所有 .nix 文件
alejandra .                 # 同上,显式调用
nix build .#checks.x86_64-linux.pre-commit-check  # 跑 alejandra + typos + prettier
```

评估测试:

```bash
nix eval .#evalTests --show-trace --print-build-logs --verbose
```

---

## 十六、参考

其他 dotfiles 仓库对本项目的影响:

- Nix Flakes
  - [NixOS-CN/NixOS-CN-telegram](https://github.com/NixOS-CN/NixOS-CN-telegram)
  - [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)
  - [taj-ny/nix-config](https://github.com/taj-ny/nix-config)

> [What y'all will need when Nix drives you to drink.](https://www.youtube.com/watch?v=Eni9PPPPBpg)
> (from hlissner's dotfiles, it really matches my feelings when I first started using NixOS...)
