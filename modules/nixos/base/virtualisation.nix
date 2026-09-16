{pkgs, ...}: {
  ###################################################################################
  #
  #  Virtualisation - Libvirt(QEMU/KVM) / Docker / LXD / WayDroid
  #
  ###################################################################################

  # Enable nested virtualization, required by security containers and nested vm.
  # This should be set per host in /hosts, not here.
  #
  ## For AMD CPU, add "kvm-amd" to kernelModules.
  # boot.kernelModules = ["kvm-amd"];
  # boot.extraModprobeConfig = "options kvm_amd nested=1";  # for amd cpu
  #
  ## For Intel CPU, add "kvm-intel" to kernelModules.
  # boot.kernelModules = ["kvm-intel"];
  # boot.extraModprobeConfig = "options kvm_intel nested=1"; # for intel cpu

  boot.kernelModules = [
    "vfio-pci"
    "kvm-amd"
  ];

  users.extraGroups.libvirtd.members = ["shey"];

  virtualisation = {
    # Usage: https://wiki.nixos.org/wiki/Waydroid
    # waydroid.enable = true;

    libvirtd = {
      enable = true;
      # hanging this option to false may cause file permission issues for existing guests.
      # To fix these, manually change ownership of affected files in /var/lib/libvirt/qemu to qemu-libvirtd.
      qemu.runAsRoot = true;
      qemu.vhostUserPackages = with pkgs; [virtiofsd];
    };
    spiceUSBRedirection.enable = true;

    # lxd.enable = true;
  };
  # To enable UEFI firmware support in Virt-Manager, Libvirt, Gnome-Boxes etc. add following snippet to your system configuration and apply it
  systemd.tmpfiles.rules = ["L+ /var/lib/qemu/firmware - - - - ${pkgs.qemu}/share/qemu/firmware"];

  # can be used to manage non-local hosts as well
  programs.virt-manager.enable = true;

  # 开机自动启动 libvirt 的 default NAT 网络(libvirtd 起来后执行)。
  # net-autostart 幂等持久化 autostart;net-start 确保当前已运行(已运行则报错,忽略)。
  systemd.services.libvirt-net-default = {
    description = "Start libvirt default network";
    after = ["libvirtd.service"];
    wants = ["libvirtd.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.libvirt}/bin/virsh net-autostart default || true
      ${pkgs.libvirt}/bin/virsh net-start default || true
    '';
  };

  # 修复 QEMU 固件路径:每次 rebuild 后 nix store 里的 OVMF 固件路径会变,
  # 而 VM XML 里写死的 /nix/store/<hash>-qemu-*/share/qemu/edk2-*.fd 会被 GC 删除,
  # 导致 EFI 启动失败("不支持 EFI")。
  # 这里把 loader / nvram 模板统一改为 libvirt 稳定路径 /run/libvirt/nix-ovmf/
  # (NixOS 每次启动自动把最新固件 symlink 到这里)。
  systemd.services.libvirt-fix-efi-firmware = {
    description = "Rewrite VM domain definitions to use stable OVMF paths";
    after = ["libvirtd.service"];
    wants = ["libvirtd.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      for xml in /var/lib/libvirt/qemu/*.xml; do
        [ -f "$xml" ] || continue
        name="$(basename "$xml" .xml)"
        # 域名不存在则跳过(避免误伤占位文件)
        ${pkgs.libvirt}/bin/virsh dominfo "$name" >/dev/null 2>&1 || continue

        # 把 write 死的 nix store 固件路径替换成稳定路径
        if grep -qE '/nix/store/[^/]+/share/qemu/edk2-(x86_64|i386)[-a-z0-9]*\.fd' "$xml"; then
          echo "fixing firmware paths for domain '$name'"
          sed -i \
            -e 's|/nix/store/[^/]*/share/qemu/edk2-x86_64-secure-code\.fd|/run/libvirt/nix-ovmf/edk2-x86_64-code.fd|g' \
            -e 's|/nix/store/[^/]*/share/qemu/edk2-x86_64-code\.fd|/run/libvirt/nix-ovmf/edk2-x86_64-code.fd|g' \
            -e 's|/nix/store/[^/]*/share/qemu/edk2-i386-vars\.fd|/run/libvirt/nix-ovmf/edk2-i386-vars.fd|g' \
            "$xml"
          # 重新加载域定义(保证 nvram 路径也被 libvirt 接受)
          ${pkgs.libvirt}/bin/virsh define "$xml" || true
        fi
      done
    '';
  };

  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment.systemPackages = with pkgs; [
    # This script is used to install the arm translation layer for waydroid
    # so that we can install arm apks on x86_64 waydroid
    #
    # https://github.com/casualsnek/waydroid_script
    # https://wiki.archlinux.org/title/Waydroid#ARM_Apps_Incompatible

    # Need to add [File (in the menu bar) -> Add connection] when start for the first time
    virt-manager

    # QEMU/KVM(HostCpuOnly), provides:
    #   qemu-storage-daemon qemu-edid qemu-ga
    #   qemu-pr-helper qemu-nbd elf2dmp qemu-img qemu-io
    #   qemu-kvm qemu-system-x86_64 qemu-system-aarch64 qemu-system-i386
    qemu_kvm

    # Install QEMU(other architectures), provides:
    #   ......
    #   qemu-loongarch64 qemu-system-loongarch64
    #   qemu-riscv64 qemu-system-riscv64 qemu-riscv32  qemu-system-riscv32
    #   qemu-system-arm qemu-arm qemu-armeb qemu-system-aarch64 qemu-aarch64 qemu-aarch64_be
    #   qemu-system-xtensa qemu-xtensa qemu-system-xtensaeb qemu-xtensaeb
    #   ......
    qemu
  ];
}
