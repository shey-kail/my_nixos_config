{
  lib,
  stdenvNoCC,
  binutils,
  python3,
  gnused,
  makeWrapper,
  symlinkJoin,
  fetchgit,
  zlib,
  stdenv,
  libGL,
  nss,
  nspr,
  freetype,
  expat,
  fontconfig,
  libX11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxcb,
  libxcb-wm,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  libxcb-util,
  dbus,
  alsa-lib,
  libxslt,
  lcms2,
  xz,
  cups,
  libdrm,
  libxkbcommon,
  libICE,
  libSM,
  libxml2,
  glibc,
  # GstarCAD 2027 deb 分片源(gitee cadsoft 仓库,469MB deb 拆 6 片,构建时 cat 合并)
  # 默认 null:真正值由 overlays/default.nix 的 gstarOverlay 用 flake 输入 cadsoft 注入
  src ? null,
}: let
  appId = "gstarsoft.gstarcad2027";

  # GstarCAD 2027 需要的系统库(自身 qtplugins/systemlibs 以外)
  systemLibs = [
    stdenv.cc.cc.lib # libstdc++
    zlib
    libGL
    nss
    nspr
    freetype
    expat
    fontconfig
    libX11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxcb
    libxcb-wm
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    libxcb-util
    dbus
    alsa-lib
    libxslt
    lcms2
    xz
    cups
    libdrm
    libxkbcommon
    libICE
    libSM
  ];

  # 修复 GstarCAD 的 spdlog 空日志路径 bug:
  # 授权流程 GcLogger::init 会 fopen("", "ab") 崩溃,LD_PRELOAD 拦截空路径重定向到可写文件
  fopenFix = stdenv.mkDerivation {
    pname = "gstar-fopen-fix";
    version = "1.0";
    src = ./fopen-fix.c;
    dontUnpack = true;
    nativeBuildInputs = [];
    buildInputs = [];
    installPhase = ''
      mkdir -p $out/lib
      gcc -shared -fPIC -o $out/lib/fopen-fix.so $src -ldl
    '';
  };
in
  stdenvNoCC.mkDerivation {
    pname = "gstar-cad";
    version = "2027.0.1";

    inherit src;

    nativeBuildInputs = [binutils python3 gnused makeWrapper];

    dontUnpack = true;

    buildPhase = ''
      runHook preBuild

      # 1. 还原 deb(cat 合并 6 片)并解开
      echo "SRC=$src"
      ls -la "$src" | head
      ls "$src"/gstar-deb* 2>&1 || echo "no gstar-deb* in src"
      cat "$src"/gstar-deb.part0* > gstar.deb || cat "$src"/gstar-deb.part* > gstar.deb
      ls -la gstar.deb
      ar x gstar.deb data.tar.xz
      mkdir -p payload
      tar -xf data.tar.xz -C payload

      # 2. 收集应用文件
      APPDIR="$out/opt/apps/${appId}"
      mkdir -p "$out/opt/apps"
      cp -r payload/opt/apps/${appId} "$out/opt/apps/"

      # 3. desktop 入口
      mkdir -p "$out/share/applications"
      cp payload/usr/share/applications/${appId}.desktop "$out/share/applications/" 2>/dev/null || true

      # 4. 修正 #!/bin/bash -> #!/usr/bin/env bash(NixOS 无 /bin/bash)
      find "$APPDIR/files" -name "*.sh" -print0 | xargs -0 sed -i 's|^#!/bin/bash|#!/usr/bin/env bash|'
      for f in "$APPDIR/files/gcad" "$APPDIR/files/gcadQtUI" "$APPDIR/files/gclauncher" "$APPDIR/files/GcQi" "$APPDIR/files/gcad.sh" "$APPDIR/files/gcadQtUI.sh"; do
        [ -e "$f" ] && chmod +x "$f" || true
      done

      # 5. desktop 文件指向我们的 wrapper
      sed -i "s|Exec=.*|Exec=$out/bin/gstarcad %F|" "$out/share/applications/${appId}.desktop" 2>/dev/null || true

      # 6. 收集系统库目录
      SYS_LIB_PATH="${lib.makeLibraryPath systemLibs}"

      # 7. wrapper(占位符模板)
      mkdir -p "$out/bin"
      cp ${./gstarcad.in} "$out/bin/gstarcad"
      sed -i \
        -e "s|@APPDIR@|$APPDIR|g" \
        -e "s|@SYS_LIB_PATH@|$SYS_LIB_PATH|g" \
        -e "s|@FOPENFIX@|${fopenFix}|g" \
        -e "s|@APPID@|${appId}|g" \
        "$out/bin/gstarcad"
      chmod +x "$out/bin/gstarcad"

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      # 内容已在 buildPhase 放入 $out
      runHook postInstall
    '';

    meta = with lib; {
      description = "GstarCAD 2027 (浩辰CAD) - Kylin deb repack for NixOS";
      homepage = "https://www.gstarcad.com";
      license = licenses.unfree;
      platforms = ["x86_64-linux"];
      maintainers = [];
    };
  }
