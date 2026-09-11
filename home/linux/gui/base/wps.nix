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

  # flatpak 沙盒对宿主机字体的感知不强:宿主机新装字体后,沙盒内
  # fontconfig 缓存(~/.var/app/<app>/cache/fontconfig)不会自动失效,
  # 导致 flatpak 应用(如 WPS)看不到新字体。
  # 这里在每次 make rebuild 时:
  #   1) 刷新宿主 fontconfig 缓存(fc-cache -f);
  #   2) 对每个已安装的 flatpak 应用,在沙盒内再跑一次 fc-cache -f。
  home.activation.flatpakFontCache = lib.hm.dag.entryAfter ["linkGeneration"] ''
    # 宿主级刷新(新安装字体进入 fontconfig 索引)
    ${pkgs.fontconfig}/bin/fc-cache -f >/dev/null 2>&1 || true

    # 沙盒级刷新:逐个 flatpak 应用,在各自沙盒内重建字体缓存
    if command -v '${pkgs.flatpak}/bin/flatpak' >/dev/null 2>&1; then
      for app in $('${pkgs.flatpak}/bin/flatpak' list --app --columns=application 2>/dev/null); do
        [ -z "$app" ] && continue
        # 沙盒内 fc-cache:失败不阻塞 rebuild
        '${pkgs.flatpak}/bin/flatpak' run --command=fc-cache -f "$app" >/dev/null 2>&1 || true
      done
    fi
  '';
}
