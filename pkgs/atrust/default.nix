# 山东通安全接入客户端(深信服 aTrust 2.4.10.25001)
#
# 来自 UOS 版 deb(山东通安全接入客户端[...]_uos_amd64.deb)。
# 这个包比另外两个复杂,因为它不只是个应用:
#
#   1) 载荷不在 opt/apps,而在 usr/share/sangfor/aTrust/(Electron 托盘 +
#      resources/{bin,lib,app,shell}:aTrustAgent 守护进程、aTrustXtunnel-64 隧道等)
#   2) 二进制里硬编码 /usr/share/sangfor/... 路径(如 aTrustTray2 找
#      resources/bin、resources/lib),store 路径塞不回去 → 由 NixOS 侧
#      systemd.tmpfiles/activationScripts 建 /usr/share/sangfor 软链桥接
#   3) 需要 root 守护进程(systemd 服务 aTrustDaemon)→ NixOS 声明式服务,
#      见 modules/nixos/desktop/shandongtong.nix
#   4) 原包还带两个 NixOS 上无法提供的内核/X 组件,已刻意跳过:
#      - usr/lib/modules-load.d/sfuem.conf  → 加载自研内核模块 sfuem(不在 nixpkgs)
#      - etc/X11/xorg.conf.d/20-sfxs.conf   → Load "sfxs" 自研 X 模块(装进去会导致 X 起不来)
#      这两项对应"终端管控/UEM"类功能,缺了不影响正常接入与隧道转发。
{
  lib,
  stdenvNoCC,
  binutils,
  xz,
  makeWrapper,
  gnused,
  # 系统库(托盘 ldd 缺失项)
  stdenv,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libGL,
  libgbm,
  libX11,
  libXcomposite,
  libXcursor,
  libXdamage,
  libXext,
  libXfixes,
  libXi,
  libXrandr,
  libXrender,
  libXScrnSaver,
  libXtst,
  libxcb,
  libxkbcommon,
  libxshmfence,
  mesa,
  nspr,
  nss,
  pango,
  zlib,
  qt5,
  systemd,
  bubblewrap,
  # deb 文件路径(由 overlays 注入)
  src ? null,
}: let
  appId = "cn.com.sangfor.atrust";
  version = "2.4.10.25001";
  installDir = "share/sangfor/aTrust";

  systemLibs = [
    stdenv.cc.cc.lib
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libGL
    libgbm
    libX11
    libXcomposite
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
    libXScrnSaver
    libXtst
    libxcb
    libxkbcommon
    libxshmfence
    mesa
    nspr
    nss
    pango
    zlib
    qt5.qtbase
    systemd
  ];
in
  stdenvNoCC.mkDerivation {
    pname = "atrust";
    inherit version;

    inherit src;

    dontUnpack = true;

    nativeBuildInputs = [binutils xz makeWrapper gnused];

    buildPhase = ''
      runHook preBuild

      # 解 UOS deb:ar 取成员,再流式解 data.tar.xz(避免整包读入内存)
      ar x "$src"
      mkdir -p payload
      xz -dc data.tar.xz | tar -x -C payload


      # 载荷:usr/share/sangfor → $out/share/sangfor
      mkdir -p "$out/share"
      cp -r payload/usr/share/sangfor "$out/share/"

      # 图标
      if [ -f payload/usr/share/pixmaps/aTrust.png ]; then
        mkdir -p "$out/share/pixmaps"
        cp payload/usr/share/pixmaps/aTrust.png "$out/share/pixmaps/"
      fi

      A="$out/${installDir}"

      # 权限:托盘/守护进程/工具都要可执行
      chmod +x "$A/aTrustTray" "$A/aTrustTray2" 2>/dev/null || true
      find "$A/resources/bin" -maxdepth 1 -type f -exec chmod +x {} \; 2>/dev/null || true
      find "$A/resources/shell" -name '*.sh' -exec chmod +x {} \; 2>/dev/null || true

      # 脚本里的 /usr/share/sangfor 改成 $out(脚本可改;二进制靠 NixOS 侧软链桥接)
      find "$A/resources/shell" -type f -name '*.sh' -print0 2>/dev/null \
        | xargs -0 -r sed -i "s|/usr/share/sangfor|$out/share/sangfor|g"

      # 守护进程脚本 shebang 修正(NixOS 无 /bin/bash)
      find "$A/resources/shell" -type f -name '*.sh' -print0 2>/dev/null \
        | xargs -0 -r sed -i 's|^#!/bin/bash|#!/usr/bin/env bash|'

      # aTrust 自带库分散在多个子目录(resources/bin 44 个、uem/lib、uem/bin 等)。
      # 注意顺序:系统库必须排在自带库"前面" —— 包里带的是 UOS 的旧 libstdc++,
      # 若让它先命中,nix 的 Qt5/icu 会因缺 CXXABI_1.3.13+ 而加载失败。
      TRUSTLIBS="$A:$A/resources/lib:$A/resources/bin:$A/uem/lib:$A/uem/bin:$A/resources/bin/plugin-daemon/aTrustDaemon"

      # 脚本直接运行 resources/bin/aTrustAgent 等二进制,需要库搜索路径。
      # 不侵入原厂脚本:另做一个 wrapper,systemd 服务指向它。
      makeWrapper "$A/resources/shell/aTrustDaemon.sh" "$out/bin/aTrustDaemon" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath systemLibs}:$TRUSTLIBS"

      # 守护进程入口:原厂 aTrustDaemon.sh 的两个问题 —— ARGS 里
      # "--plugin-cmd" 本版本不识别、且末尾有个裸管道导致 $! 记错 PID。
      # 这里直接以前台方式跑 agent(--plugin plugin-daemon),
      # 由 systemd 的 Type=simple 直接跟踪进程。
      makeWrapper "$A/resources/bin/aTrustAgent" "$out/bin/aTrustAgent" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath systemLibs}:$TRUSTLIBS" \
        --add-flags "--plugin" \
        --add-flags "plugin-daemon"

      # 核心服务入口:托盘只启动 --plugin plugin-daemon,但托盘自己需要连
      # "plugins/aTrustCore/thrift"(核心服务)。在 UOS 上由托盘去拉起,
      # 但 NixOS 上托盘(spawn 出来的是普通用户进程)锁不上 root 建的
      # lockfile → "lock file lock fail / Master instance already running"
      # → 核心服务永远起不来(日志里失败 499 次),托盘于是报"核心服务未启动"。
      # 这里提供入口,由 systemd 以 root 常驻启动(参数取自托盘自己的拉起命令)。
      makeWrapper "$A/resources/bin/aTrustAgent" "$out/bin/aTrustAgentCore" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath systemLibs}:$TRUSTLIBS" \
        --add-flags "--plugin" \
        --add-flags "plugins/aTrustCore" \
        --add-flags "--enable-http" \
        --add-flags "--enable-event-center"

      # 托盘启动脚本
      #
      # 两件事:
      #   1) Qt 平台插件:托盘会**另起一个 Qt 托盘子进程**(aTrustTray2),
      #      它需要平台插件,否则 SIGABRT("Could not find the Qt platform
      #      plugin xcb in \"\"")。给出 nix qtbase 的插件目录并强制 xcb
      #      (Wayland 会话下有 XWayland;X11 会话同样适用)。
      #   2) 伪造 /etc/os-release:官方只认 uos/kylin/ubuntu/neokylin,
      #      nixos 会被当成未知发行版(Qt 托盘会打 "not support system os"
      #      并跳过发行版专属集成)。用 bwrap 把假的 os-release 挂进去,
      #      让应用以为跑在 Ubuntu 20.04 上(UOS v20 / Kylin V10 同源)。
      #      bwrap 不可用时自动降级为直接启动。
      mkdir -p "$out/share/atrust"
      cat > "$out/share/atrust/os-release" <<'OSREL'
NAME="Ubuntu"
VERSION="20.04.6 LTS (Focal Fossa)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 20.04.6 LTS"
VERSION_ID="20.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
VERSION_CODENAME=focal
UBUNTU_CODENAME=focal
OSREL

      QTPLUG=$(echo ${qt5.qtbase.bin}/lib/qt-*/plugins/platforms)
      mkdir -p "$out/bin"
      write_tray_launcher() {
        # 用引号 heredoc:里面的 shell 变量原样保留;
        # 构建期要注入的值走 @占位符@,最后 sed 替换
        cat > "$1" <<'LAUNCHER'
#!/bin/bash
# aTrust 托盘启动器(nix 打包生成)
export LD_LIBRARY_PATH="@LIBS@''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="@QTPLUG@"
export QT_QPA_PLATFORM="xcb"
APP="@APP@"
FAKE="@FAKE@"
BWRAP="@BWRAP@"
if "$BWRAP" --dev-bind / / --ro-bind "$FAKE" /etc/os-release true 2>/dev/null; then
  exec "$BWRAP" --dev-bind / / --ro-bind "$FAKE" /etc/os-release "$APP" --no-sandbox --disable-gpu "$@"
fi
exec "$APP" --no-sandbox --disable-gpu "$@"
LAUNCHER
        sed -i \
          -e "s|@LIBS@|${lib.makeLibraryPath systemLibs}:$TRUSTLIBS|" \
          -e "s|@QTPLUG@|$QTPLUG|" \
          -e "s|@APP@|$A/aTrustTray|" \
          -e "s|@FAKE@|$out/share/atrust/os-release|" \
          -e "s|@BWRAP@|${bubblewrap}/bin/bwrap|" \
          "$1"
        chmod +x "$1"
      }
      write_tray_launcher "$out/bin/aTrustTray"
      write_tray_launcher "$out/bin/atrust"

      # desktop 入口
      mkdir -p "$out/share/applications"
      cat > "$out/share/applications/${appId}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=山东通安全接入客户端
Name[en]=Sangfor aTrust
Comment=Sangfor SSL SDP client
Exec=$out/bin/aTrustTray --no-sandbox --disable-gpu
Icon=aTrust
Terminal=false
Categories=Network;
EOF

      # 原厂 systemd 单元一并留着做参考(实际由 NixOS 模块声明式提供)
      mkdir -p "$out/share/atrust-systemd"
      cp -r payload/usr/lib/systemd/system/*.service "$out/share/atrust-systemd/" 2>/dev/null || true

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      runHook postInstall
    '';

    meta = with lib; {
      description = "Sangfor aTrust (山东通安全接入客户端) - UOS deb rebundle for NixOS";
      homepage = "https://www.sangfor.com";
      license = licenses.unfree;
      platforms = ["x86_64-linux"];
    };
  }
