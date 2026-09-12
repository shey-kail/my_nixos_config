# 把公文国标字体(仿宋_GB2312 / 楷体_GB2312,来自 office-fonts 包)
# 同步进**所有** flatpak 应用的沙盒可见字体目录,并刷新各沙盒字体缓存。
#
# 背景:flatpak 沙盒默认看不到宿主 /nix/store 的字体。要让 WPS/微信等
# 应用使用仿宋_GB2312 / 楷体_GB2312,必须把字体文件复制进每个应用的
#     ~/.var/app/<appid>/data/fonts
# (该路径在沙盒内即 $XDG_DATA_HOME/fonts,fontconfig 自动扫描),再在
# 沙盒内跑 fc-cache -f 重建缓存。本模块在每次 make rebuild 时自动完成。
{
  config,
  pkgs,
  lib,
  ...
}: let
  # office-fonts 包输出路径(含 FangSong_GB2312.ttf / KaiTi_GB2312.ttf)
  # 由 flatpak-nixos 模块的 overlay 注册进 pkgs。
  fontSrc = "${pkgs.office-fonts}/share/fonts/truetype/office";
in {
  home.activation.flatpakFontsSync = lib.hm.dag.entryAfter ["linkGeneration"] ''
    # 源字体目录必须存在(office-fonts 已装)
    if [ ! -d '${fontSrc}' ]; then
      echo "警告:office-fonts 字体目录不存在: ${fontSrc}" >&2
      exit 0
    fi

    # 枚举所有 flatpak 应用
    apps=$('${pkgs.flatpak}/bin/flatpak' list --app --columns=application 2>/dev/null || true)
    [ -z "$apps" ] && exit 0

    for app in $apps; do
      sandbox_fonts="$HOME/.var/app/$app/data/fonts"
      # 建目录并复制字体(只复制 office 目录下的文件,避免残留)
      mkdir -p "$sandbox_fonts"
      for f in '${fontSrc}'/*.ttf '${fontSrc}'/*.ttc; do
        [ -f "$f" ] && cp -f "$f" "$sandbox_fonts/$(basename "$f")"
      done

      # 沙盒内刷新字体缓存
      '${pkgs.flatpak}/bin/flatpak' run --command=fc-cache "$app" -f >/dev/null 2>&1 \
        || echo "  警告:$app fc-cache 刷新失败(沙盒可能无法启动)" >&2
    done

    echo "已同步公文字体到所有 flatpak 沙盒并刷新缓存。"
  '';
}
