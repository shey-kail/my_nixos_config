# 山东视频会议客户端(sdmeeting / com.sdongmeeting.linuxclient)
#
# 来自 UOS 版 deb(sdmeeting.linuxclient_103.9.2.23577-..._amd64_x86_uos.deb)。
# 结构与 GstarCAD 打包经验一致:opt/apps/<appid>/ 重绑 + wrapper 补系统库。
#
# 这个包恰好是最省事的:自带的 launch.sh 用 readlink 解析自身路径,
# 把 PATH/LD_LIBRARY_PATH/QT_PLUGIN_PATH 全部相对设置后 exec 主程序,
# 所以直接装到 $out 下即可,不需要改脚本里的任何绝对路径。
# 缺的系统库(libstdc++/libX11/zlib 等)由 wrapper 注入。
{
  lib,
  stdenvNoCC,
  binutils,
  xz,
  makeWrapper,
  # 系统库(主程序 ldd 缺失项)
  stdenv,
  zlib,
  libX11,
  libXext,
  libxcb,
  libxkbfile,
  libxkbcommon,
  libXcomposite,
  libXdamage,
  libXfixes,
  libXrandr,
  libXrender,
  libXi,
  libXtst,
  libXcursor,
  libXScrnSaver,
  libxshmfence,
  libGL,
  libgbm,
  libgpg-error,
  fontconfig,
  freetype,
  expat,
  dbus,
  alsa-lib,
  nss,
  nspr,
  cups,
  libdrm,
  mesa,
  gdk-pixbuf,
  glib,
  gtk3,
  pango,
  cairo,
  at-spi2-atk,
  at-spi2-core,
  libuuid,
  libsecret,
  # deb 文件路径(由 overlays 注入)
  src ? null,
}: let
  appId = "com.sdongmeeting.linuxclient";
  version = "103.9.2.23577";

  systemLibs = [
    stdenv.cc.cc.lib
    zlib
    libX11
    libXext
    libxcb
    libxkbfile
    libxkbcommon
    libXcomposite
    libXdamage
    libXfixes
    libXrandr
    libXrender
    libXi
    libXtst
    libXcursor
    libXScrnSaver
    libxshmfence
    libGL
    libgbm
    libgpg-error
    fontconfig
    freetype
    expat
    dbus
    alsa-lib
    nss
    nspr
    cups
    libdrm
    mesa
    gdk-pixbuf
    glib
    gtk3
    pango
    cairo
    at-spi2-atk
    at-spi2-core
    libuuid
    libsecret
  ];
in
  stdenvNoCC.mkDerivation {
    pname = "sdmeeting";
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
      sed -e "s|^Exec=.*|Exec=$out/bin/sdmeeting %u|" \
          -e "s|^Icon=.*|Icon=${appId}|" \
          "payload/opt/apps/${appId}/entries/applications/${appId}.desktop" \
          > "$out/share/applications/${appId}.desktop"

      # wrapper:补系统库后交给自带 launch.sh(它自己设 Qt 插件路径)
      mkdir -p "$out/bin"
      makeWrapper "$out/opt/apps/${appId}/files/launch.sh" "$out/bin/sdmeeting" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath systemLibs}" \
        --prefix PATH : "${lib.makeBinPath [dbus]}"

      chmod +x "$out/opt/apps/${appId}/files/launch.sh"
      chmod +x "$out/opt/apps/${appId}/files/bin/qt_linux_pc_client" 2>/dev/null || true

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      runHook postInstall
    '';

    meta = with lib; {
      description = "山东视频会议客户端 (SDongMeeting) - UOS deb rebundle for NixOS";
      homepage = "https://www.sdt.sdbdc.cn";
      license = licenses.unfree;
      platforms = ["x86_64-linux"];
    };
  }
