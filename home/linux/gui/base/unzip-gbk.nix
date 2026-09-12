# 永久解决 zip 压缩包内中文文件名乱码问题。
#
# 背景:Windows 上创建的 zip,文件名是 GBK/GB18030 编码,而 Linux 的
# unzip 默认按 UTF-8 处理,中文会乱码。unzip 提供 `-O CHARSET` 指定源编码,
# 但每次手动敲很麻烦。
#
# 方案:提供一个自动的 `unzip` wrapper(放在 home 层,优先级高于系统 unzip):
#   - 若命令行带 -O/-I 则原样透传(用户显式指定优先)
#   - 否则先按 GBK(-O GBK)尝试解压,抛错则回退 UTF-8(-O UTF-8)
# 同时把 unar(自动检测编码的多格式解压器)一并装上备用。
{pkgs, ...}: {
  home.packages = [
    # unar:自动检测 zip/rar 等文件名编码,后台/手动场景的可靠备用
    pkgs.unar

    # 自定义 unzip wrapper,接入 home 的 bin(PATH 优先级最高)
    (pkgs.writeShellScriptBin "unzip" ''
      # 若用户显式给了 -O/-I,原样透传
      case "$*" in
        *-O*|*-I*) exec '${pkgs.unzip}/bin/unzip' "$@" ;;
      esac

      # 先试 GBK(Windows zip 常见),失败则回退 UTF-8
      if '${pkgs.unzip}/bin/unzip' -O GBK "$@"; then
        exit 0
      else
        exec '${pkgs.unzip}/bin/unzip' -O UTF-8 "$@"
      fi
    '')
  ];
}
