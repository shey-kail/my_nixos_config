{
  lib,
  fetchurl,
  stdenv,
}:

stdenv.mkDerivation rec {
  pname = "netflow";
  version = "3.0.7";

  src = fetchurl {
    url = "https://github.com/shey-kail/qyt-openwrt-client/releases/download/3.0.7/luci-app-qytclient_all.ipk";
    sha256 = "89fac8b93b0e418bd9cc7504918d25d2e44a21b900dfeaf70b9720c36592680c";
  };

  # .ipk 实际是嵌套的 gzip tarball(外层包含 debian-binary / data.tar.gz / control.tar.gz;
  # 内层 data.tar.gz 才是真正的应用文件)。stdenv 默认 unpackFile 不认 .ipk,完全重写。
  unpackPhase = ''
    runHook preUnpack
    # 跳过 stdenv 默认的 unpackFile
    :
    # 解外层:得到 debian-binary / data.tar.gz / control.tar.gz
    tar -xzf "$src"
    runHook postUnpack
  '';

  buildPhase = ''
    runHook preBuild
    # 从内层 data.tar.gz 提取 x86_64 二进制
    tar -xzf data.tar.gz ./usr/bin/netflow_x86_64
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 usr/bin/netflow_x86_64 $out/bin/netflow
    runHook postInstall
  '';

  meta = with lib; {
    description = "青云梯 Lite Proxy Client";
    homepage = "https://github.com/shey-kail/qyt-openwrt-client";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
