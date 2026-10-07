# dae 托盘图标:状态指示 + 启停控制 + 查看当前节点/日志
#
# 由 home-manager 的用户级 systemd 服务拉起(见 home/linux/gui/base/dae-tray.nix),
# 所以这里只负责把 Python(GI)环境、GI typelib 搜索路径和依赖工具打包好。
{
  lib,
  stdenvNoCC,
  python3,
  makeWrapper,
  # GI / GTK 相关
  gtk3,
  gdk-pixbuf,
  pango,
  glib,
  at-spi2-core,
  harfbuzz,
  libayatana-appindicator,
  gobject-introspection,
  # 运行期工具
  systemd,
  coreutils,
  kdePackages,
  ...
}:
let
  pythonEnv = python3.withPackages (ps: [ ps.pygobject3 ]);

  # GI typelib 搜索路径。
  # 必须用 .out:pango / glib 的**默认输出是 -bin**,那里没有 typelib,
  # 直接用 pkgs.pango 会得到空的 lib/girepository-1.0(makeSearchPath 取默认输出)。
  # xlib-2.0 与 cairo/fontconfig 的 typelib 来自 gobject-introspection。
  giPkgs = [
    gtk3.out
    gdk-pixbuf.out
    pango.out
    glib.out
    at-spi2-core.out
    harfbuzz.out
    libayatana-appindicator.out
    gobject-introspection
  ];
  giTypelibs = lib.makeSearchPath "lib/girepository-1.0" giPkgs;
  giLibs = lib.makeLibraryPath [
    gtk3
    gdk-pixbuf
    pango
    glib
    at-spi2-core
    harfbuzz
    libayatana-appindicator
  ];

  # 复用 dae 目录下的节点查询工具(pkexec 以 root 运行它,才能读 /etc/dae/*.sub)
  whichNode = ../../modules/nixos/base/dae/which-node.py;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "dae-tray";
  version = "1.0.0";

  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/libexec
    install -m0644 ${whichNode} $out/libexec/which-node.py

    makeWrapper ${pythonEnv}/bin/python3 $out/bin/dae-tray \
      --add-flags ${./dae-tray.py} \
      --prefix GI_TYPELIB_PATH : "${giTypelibs}" \
      --prefix LD_LIBRARY_PATH : "${giLibs}" \
      --prefix PATH : "${lib.makeBinPath [ systemd coreutils kdePackages.konsole ]}" \
      --set DAETRAY_PYTHON "${pythonEnv}/bin/python3" \
      --set DAETRAY_WHICH_NODE "$out/libexec/which-node.py" \
      --set DAETRAY_SYSTEMCTL "${systemd}/bin/systemctl" \
      --set DAETRAY_KONSOLE "${kdePackages.konsole}/bin/konsole"
    runHook postInstall
  '';

  meta = {
    description = "dae tray indicator (status + start/stop + current node)";
    platforms = [ "x86_64-linux" ];
    mainProgram = "dae-tray";
  };
})
