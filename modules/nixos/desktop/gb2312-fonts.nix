# 公文标准中文字体包(GB/T 9704-2012 党政机关公文格式常用字库)
#
# 来源:https://github.com/DoveOutland/Common-Chinese-office-fonts-font-library-
# 解决 WPS/公文文档引用 "仿宋_GB2312"、"楷体_GB2312"、"方正小标宋简体"
# 等确切字体名时缺失的问题。包含:仿宋/黑体/楷体/宋体(基础四套)、
# 仿宋_GB2312、楷体_GB2312、方正小标宋/大标宋/仿宋_GBK/楷体_GBK/黑体_GBK,
# 以及 Times New Roman 西文配套。
{
  lib,
  stdenvNoCC,
}: let
  fonts = [
    ./wps-fonts/FangSong_GB2312.ttf
    ./wps-fonts/KaiTi_GB2312.ttf
    ./wps-fonts/Fangsong.ttf
    ./wps-fonts/Kaiti.ttf
    ./wps-fonts/SimSun.ttc
    ./wps-fonts/SimHei.ttf
    ./wps-fonts/FZXiaoBiaoSong.ttf
    ./wps-fonts/FZXiaoBiaoSong_GBK.ttf
    ./wps-fonts/FZDaBiaoSong.ttf
    ./wps-fonts/FZDaBiaoSongJF.ttf
    ./wps-fonts/FZFangSong.ttf
    ./wps-fonts/FZFangSong_GBK.ttf
    ./wps-fonts/FZKaiTi.ttf
    ./wps-fonts/FZKaiTi_GBK.ttf
    ./wps-fonts/FZHeiTi.ttf
    ./wps-fonts/FZHeiTi_GBK.ttf
    ./wps-fonts/times-new-roman/times.ttf
    ./wps-fonts/times-new-roman/timesbd.ttf
    ./wps-fonts/times-new-roman/timesbi.ttf
    ./wps-fonts/times-new-roman/timesi.ttf
  ];
in
  stdenvNoCC.mkDerivation {
    pname = "gb2312-fonts";
    version = "2025-05";

    src = null;

    dontUnpack = true;
    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/fonts/truetype/gb2312
      ${builtins.concatStringsSep "\n" (map (f: "cp '${f}' $out/share/fonts/truetype/gb2312/") fonts)}
      runHook postInstall
    '';

    meta = with lib; {
      description = "GB/T 9704-2012 official document Chinese font library (FangSong_GB2312, KaiTi_GB2312, 方正小标宋 etc.)";
      homepage = "https://github.com/DoveOutland/Common-Chinese-office-fonts-font-library-";
      license = licenses.free;
      platforms = platforms.all;
    };
  }
