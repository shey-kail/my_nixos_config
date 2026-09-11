# 公文标准中文字体包(GB/T 9704-2012 党政机关公文格式常用字库)
#
# 来自独立字体仓库 /home/shey/Codes/office_fonts(flake input `office-fonts`)。
# 解决 WPS/公文文档引用 "仿宋_GB2312"、"楷体_GB2312"、"方正小标宋简体"
# 等确切字体名时缺失的问题。包含:仿宋/黑体/楷体/宋体(基础四套)、
# 仿宋_GB2312、楷体_GB2312、方正小标宋/大标宋/仿宋_GBK/楷体_GBK/黑体_GBK,
# 以及 Times New Roman 西文配套。
{
  lib,
  stdenvNoCC,
  inputs,
}: let
  fonts = [
    "FangSong_GB2312.ttf"
    "KaiTi_GB2312.ttf"
    "Fangsong.ttf"
    "Kaiti.ttf"
    "SimSun.ttc"
    "SimHei.ttf"
    "FZXiaoBiaoSong.ttf"
    "FZXiaoBiaoSong_GBK.ttf"
    "FZDaBiaoSong.ttf"
    "FZDaBiaoSongJF.ttf"
    "FZFangSong.ttf"
    "FZFangSong_GBK.ttf"
    "FZKaiTi.ttf"
    "FZKaiTi_GBK.ttf"
    "FZHeiTi.ttf"
    "FZHeiTi_GBK.ttf"
    "times-new-roman/times.ttf"
    "times-new-roman/timesbd.ttf"
    "times-new-roman/timesbi.ttf"
    "times-new-roman/timesi.ttf"
  ];
  fontDir = inputs.office-fonts;
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
      ${builtins.concatStringsSep "\n" (map (f: "cp '${fontDir}/${f}' $out/share/fonts/truetype/gb2312/") fonts)}
      runHook postInstall
    '';

    meta = with lib; {
      description = "GB/T 9704-2012 official document Chinese font library (FangSong_GB2312, KaiTi_GB2312, 方正小标宋 etc.)";
      homepage = "https://github.com/DoveOutland/Common-Chinese-office-fonts-font-library-";
      license = licenses.free;
      platforms = platforms.all;
    };
  }
