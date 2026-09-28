# 山东通客户端(shandongtong 3.0.46000,腾讯企业微信系)
#
# 来自 UOS 版 deb(山东通客户端Hygon.ZHAOXIN.3.0.46000.9N02.x86.UOSv20.deb)。
# 结构与 GstarCAD 打包经验一致:opt/apps/<appid>/ 重绑 + wrapper 补系统库。
#
# 这是个 Electron 应用(自带 chrome-sandbox / icudtl.dat / app.asar + 63 个 .so),
# 主程序必须能从自身目录找到 resources/app.asar,所以保持 opt/apps 目录结构完整。
# NixOS 上 chrome-sandbox 无法 setuid,按惯例加 --no-sandbox 运行。
{
  lib,
  stdenvNoCC,
  binutils,
  xz,
  makeWrapper,
  # 系统库(主程序 ldd 缺失项)
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
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libxcb,
  libxkbcommon,
  libxshmfence,
  mesa,
  nspr,
  nss,
  pango,
  zlib,
  # deb 文件路径(由 overlays 注入)
  src ? null,
}: let
  appId = "shandongtong";
  version = "3.0.46000";

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
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxcb
    libxkbcommon
    libxshmfence
    mesa
    nspr
    nss
    pango
    zlib
  ];
in
  stdenvNoCC.mkDerivation {
    pname = "shandongtong";
    inherit version;

    inherit src;

    dontUnpack = true;

    nativeBuildInputs = [binutils xz makeWrapper];

    buildPhase = ''
      runHook preBuild

      # 解 UOS deb:ar 取成员,再流式解 data.tar.xz(避免整包读入内存)
      ar x "$src"
      mkdir -p payload
      xz -dc data.tar.xz | tar -x -C payload


      APPDIR="$out/opt/apps/${appId}"
      mkdir -p "$out/opt/apps"
      cp -r "payload/opt/apps/${appId}" "$out/opt/apps/"

      # 图标
      if [ -d "payload/opt/apps/${appId}/entries/icons" ]; then
        mkdir -p "$out/share/icons"
        cp -r "payload/opt/apps/${appId}/entries/icons/hicolor" "$out/share/icons/" 2>/dev/null || true
      fi

      # desktop 入口(指向我们的 wrapper)
      mkdir -p "$out/share/applications"
      sed -e "s|^Exec=.*|Exec=$out/bin/shandongtong %U|" \
          -e "s|^Icon=.*|Icon=${appId}|" \
          "payload/opt/apps/${appId}/entries/applications/${appId}.desktop" \
          > "$out/share/applications/${appId}.desktop"

      # wrapper:Electron 运行环境
      #  - 自带 .so 目录:$out/opt/apps/<appid>/files
      #  - 系统库:见 systemLibs
      #  - --no-sandbox:NixOS 无法给 chrome-sandbox 设 setuid
      mkdir -p "$out/bin"
      makeWrapper "$APPDIR/files/${appId}" "$out/bin/shandongtong" \
        --prefix LD_LIBRARY_PATH : "$APPDIR/files:${lib.makeLibraryPath systemLibs}" \
        --add-flags "--no-sandbox" \
        --set CHROME_DEVEL_SANDBOX "$APPDIR/files/chrome-sandbox"

      chmod +x "$APPDIR/files/${appId}" "$APPDIR/files/chrome_crashpad_handler" 2>/dev/null || true

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      runHook postInstall
    '';

    meta = with lib; {
      description = "山东通客户端 (ShandongTong) - UOS deb rebundle for NixOS";
      homepage = "https://www.sdt.sdbdc.cn";
      license = licenses.unfree;
      platforms = ["x86_64-linux"];
    };
  }
