# 本地 GB2312 国标字体包(仿宋_GB2312 / 黑体 / 宋体)
#
# 来源:https://github.com/XiangyunHuang/fonts(公文/证件字体收集)
# 解决 WPS/公文文档引用 "仿宋_GB2312"、"楷体_GB2312" 等字体名时缺失的问题。
# 这些是 GB2312 标准定义的国标字体,与 foundertype/windows 里名字不同的文件。
{
  lib,
  stdenvNoCC,
}: let
  fonts = [
    ./wps-fonts/FangSong_GB2312.ttf
    ./wps-fonts/SimHei.ttf
    ./wps-fonts/SimSun.ttc
  ];
in
  stdenvNoCC.mkDerivation {
    pname = "gb2312-fonts";
    version = "1.0.0";

    src = null;

    dontUnpack = true;
    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/fonts/truetype/gb2312
      ${builtins.concatStringsSep "\n" (map (f: "cp ${f} $out/share/fonts/truetype/gb2312/") fonts)}
      runHook postInstall
    '';

    meta = with lib; {
      description = "GB2312 national standard fonts (FangSong_GB2312, SimHei, SimSun)";
      homepage = "https://github.com/XiangyunHuang/fonts";
      license = licenses.free;
      platforms = platforms.all;
    };
  }
