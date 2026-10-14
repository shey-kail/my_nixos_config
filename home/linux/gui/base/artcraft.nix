{ artcraft, ... }:
{
  # ArtCraft 创意套件(社区非官方打包,上游为预编译 Linux 二进制)
  # PhotoCraft / VectorCraft / FilmCraft / LightCraft / PdfCraft / EffectCraft
  # DesignCraft / GridCraft / WordCraft / DeckCraft / CadCraft / SoundCraft
  #
  # 来源:https://github.com/Devitek/artcraft-nixos
  # 注意:这些是 egui + wgpu 的 GPU 应用,需要 hardware.graphics.enable = true
  # (nixpkgs 的 graphical-desktop 模块在启用桌面后已默认打开)。
  imports = [ artcraft.homeManagerModules.default ];

  programs.artcraft = {
    enable = true;
    # apps 默认 = 当前系统可用的全部应用(x86_64-linux 上 12 个)。
    # 只想装其中几个时,取消注释并按需列出:
    # apps = [ "photocraft" "vectorcraft" "filmcraft" "soundcraft" ];
  };
}
