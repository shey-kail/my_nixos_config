{pkgs, ...}: {
  # all fonts are linked to /nix/var/nix/profiles/system/sw/share/X11/fonts
  fonts = {
    # use fonts specified by user rather than default ones
    enableDefaultPackages = false;
    fontDir.enable = true;

    # kmscon.config.font-name 走 fontconfig,所以必须开
    fontconfig.enable = true;

    packages = with pkgs; [
      # Noto 系列字体(Google 主导),只装彩色 emoji,思源已经覆盖 CJK
      noto-fonts-color-emoji # 彩色的表情符号字体

      # 思源系列字体(Adobe + Google 共同开发),CJK + 拉丁字符 fallback 链主力
      source-han-sans # 思源黑体
      source-han-serif # 思源宋体

      # nerdfonts:图标 + 等宽,terminal/IDE 必备
      # https://github.com/NixOS/nixpkgs/blob/nixos-unstable-small/pkgs/data/fonts/nerd-fonts/manifests/fonts.json
      nerd-fonts.symbols-only # symbols icon only
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka

      # kmscon 终端用
      source-code-pro

      # Windows 11 字体(来自 nix-ttf-ms-win11-auto,微软 EULA,需合法 Win11 license)
      # 放最后,优先级最高,覆盖任何 alias 冲突的 fontconfig fallback
      ttf-ms-win11-auto         # 英文:Arial/Calibri/Segoe UI/Times New Roman/Cambria/Tahoma 等
      ttf-ms-win11-auto-zh_cn   # 简体中文:Microsoft YaHei(微软雅黑)/SimSun(宋体)
      ttf-ms-win11-fod-auto-hans # 简体中文 FOD:FangSong(仿宋)/KaiTi(楷体)/SimHei(黑体)/DengXian(等线)
    ];

    # user defined fonts
    # the reason there's Noto Color Emoji everywhere is to override DejaVu's
    # B&W emojis that would sometimes show instead of some Color emojis
    fontconfig.defaultFonts = {
      serif = ["Source Han Serif SC" "Source Han Serif TC" "Noto Color Emoji"];
      sansSerif = ["Source Han Sans SC" "Source Han Sans TC" "Noto Color Emoji"];
      monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
      emoji = ["Noto Color Emoji"];
    };
  };

  # https://wiki.archlinux.org/title/KMSCON
  services.kmscon = {
    # Use kmscon as the virtual console instead of gettys.
    # kmscon is a kms/dri-based userspace virtual terminal implementation.
    # It supports a richer feature set than the standard linux console VT,
    # including full unicode support, and when the video card supports drm should be much faster.
    enable = true;
    extraOptions = "--term xterm-256color";
    config = {
      # 字体名走 fontconfig,source-code-pro 已加进 fonts.packages
      font-name = "Source Code Pro";
      font-size = 12;
      # Whether to use 3D hardware acceleration to render the console.
      hwaccel = true;
    };
  };
}