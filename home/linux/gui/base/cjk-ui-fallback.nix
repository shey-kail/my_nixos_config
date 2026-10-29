{pkgs, ...}: {
  # PDFCraft(0.13)的界面中文兜底不在 fontconfig 里做匹配,而是:
  #   解析 /etc/fonts/fonts.conf 收集 <dir> → 递归扫描 → **按文件名**挑候选
  #   (wqy-microhei.ttc / wqy-zenhei.ttc / DroidSansFallbackFull.ttf / uming.ttc)。
  # NixOS 生成的 /etc/fonts/fonts.conf 只声明了 ~/.local/share/fonts 和 DejaVu 的
  # store 目录,所以中文界面没有可用的兜底 face → 豆腐块(日志里只会看到
  # DejaVuSans 那条 "interface font fallback")。
  #
  # 这里把文泉驿微米黑放进它声明的 ~/.local/share/fonts,文件名保持它认得的
  # wqy-microhei.ttc。该目录不会被 Flatpak 映射进沙箱,所以不影响 WPS 的字体视图。
  home.file.".local/share/fonts/wqy-microhei.ttc".source = "${pkgs.wqy_microhei}/share/fonts/truetype/wqy-microhei.ttc";
}
