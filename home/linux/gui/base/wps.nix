# 为 flatpak 版 WPS(cn.wps.wps_365)按需提供办公字体。
#
# 背景:nixpkgs 的 fix-fonts-icons.patch 会把宿主全部字体 + /nix/store 暴露给
#       所有 flatpak 应用。这里改为更克制的方式:把 WPS 需要的办公字体
#       **复制**进 WPS 自己的数据目录
#         ~/.var/app/cn.wps.wps_365/data/fonts
#       (该路径正是 flatpak 沙箱里的 $XDG_DATA_HOME/fonts,
#        runtime fontconfig 的 <dir prefix="xdg">fonts</dir> 会自动扫描它,
#        且这个 per-app 目录只有 WPS 的沙箱看得到)。
#       因为是真实副本,WPS 沙箱里完全看不到 /nix/store,其它应用也不受影响。
{
  config,
  pkgs,
  lib,
  ...
}: {
  # 每次 home-manager activate(即 make rebuild)时把选定字体同步进 WPS 数据目录
  home.activation.wpsFonts = let
    # 开放给 WPS 的字体包(其余 nerd/fira/inter/material 一律不给)
    fontSites = with pkgs; [
      windows-fonts # 微软办公字体(arial/times/calibri…)
      source-han-sans # 思源黑体
      source-han-serif # 思源宋体
      harmonyos-sans-fonts # 华为 HarmonyOS Sans
      foundertype-gpu-fonts # 方正字库
    ];
    dest = "${config.home.homeDirectory}/.var/app/cn.wps.wps_365/data/fonts";
  in
    lib.hm.dag.entryAfter ["linkGeneration"] ''
      # 组装一个干净的字体暂存目录(只含本次选定的字体)
      mkdir -p '${dest}.tmp'
      ${
        builtins.concatStringsSep "\n" (
          builtins.map (
            site: ''
              for f in '${site}'/*; do
                [ -f "$f" ] && cp -f "$f" '${dest}.tmp'/$(basename "$f")
              done
            ''
          )
          fontSites
        )
      }
      # 用暂存目录原子替换旧的字体目录(避免残留旧/多余字体)
      rm -rf '${dest}'
      mv '${dest}.tmp' '${dest}'
    '';
}
