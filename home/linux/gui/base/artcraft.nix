{artcraft, ...}: {
  # ArtCraft 创意套件(社区非官方打包,上游为预编译 Linux 二进制)
  # 来源:https://github.com/Devitek/artcraft-nixos
  #
  # 这些是 egui + wgpu 的 GPU 应用,需要 hardware.graphics.enable = true
  # (nixpkgs 的 graphical-desktop 模块在启用桌面后已默认打开)。
  imports = [artcraft.homeManagerModules.default];

  programs.artcraft = {
    enable = true;
    # 显式列出要装的 11 个应用(不写 apps 则默认装全部,
    # 但上游 soundcraft 的发布包在本机网络下下载经常挂起,故不纳入)。
    # 以后想加 soundcraft,把 "soundcraft" 追加进这个列表即可。
    apps = [
      "cadcraft" # CAD
      "deckcraft" # 演示文稿
      "designcraft" # 设计与排版
      "effectcraft" # 视觉特效
      "filmcraft" # 视频剪辑
      "gridcraft" # 表格
      "lightcraft" # 照片调光
      "pdfcraft" # PDF 工具
      "photocraft" # 位图编辑
      "vectorcraft" # 矢量图形
      "wordcraft" # 文字处理
    ];
  };
}
