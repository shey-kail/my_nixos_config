{
  artcraft,
  lib,
  pkgs,
  ...
}: let
  # ArtCraft 的文件对话框走 rfd:优先 XDG portal,失败再退回 zenity。
  # 上游打包的 wrapper 只给 LD_LIBRARY_PATH 加了 GUI/GPU 库,**没有 libdbus**,
  # 于是 rfd 连 portal 都连不上(libdbus-1.so not found)→ 只要 zenity 也不在,
  # 「打开文件」就完全没反应。这里给每个应用的 wrapper 再补一层 dbus,
  # portal(plasma-xdg-desktop-portal-kde)就能弹出原生 KDE 对话框。
  # wrapProgram 支持链式包装(会生成 .<name>-wrapped_),不会破坏原有的库路径。
  available = import "${artcraft}/pkgs" {inherit pkgs;};
  withDbus = lib.mapAttrs (_: p:
    p.overrideAttrs (old: {
      postFixup =
        (old.postFixup or "")
        + ''
          for bin in "$out"/bin/*; do
            [ -f "$bin" ] && [ -x "$bin" ] || continue
            wrapProgram "$bin" --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [pkgs.dbus]}
          done
        '';
    }))
  available;
in {
  # ArtCraft 创意套件(社区非官方打包,上游为预编译 Linux 二进制)
  # 来源:https://github.com/Devitek/artcraft-nixos
  #
  # 这些是 egui + wgpu 的 GPU 应用,需要 hardware.graphics.enable = true
  # (nixpkgs 的 graphical-desktop 模块在启用桌面后已默认打开)。
  imports = [artcraft.homeManagerModules.default];

  programs.artcraft = {
    enable = true;
    # 用补过 libdbus 的包集合(见上面的 withDbus)
    packages = withDbus;
    # 显式列出要装的应用(不写 apps 则默认装全部,
    # 但上游 soundcraft 的发布包在本机网络下下载经常挂起,故不纳入)。
    # 以后想加 soundcraft,把 "soundcraft" 追加进这个列表即可。
    apps = [
      "cadcraft" # CAD
      "deckcraft" # 演示文稿
      "filmcraft" # 视频剪辑
      "gridcraft" # 表格
      "pdfcraft" # PDF 工具
      "photocraft" # 位图编辑
      "wordcraft" # 文字处理
    ];
  };
}
