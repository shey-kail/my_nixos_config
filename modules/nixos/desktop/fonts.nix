{pkgs, ...}: {
  # all fonts are linked to /nix/var/nix/profiles/system/sw/share/X11/fonts
  fonts = {
    # use fonts specified by user rather than default ones
    enableDefaultPackages = false;
    fontDir.enable = true;

    # kmscon.config.font-name 走 fontconfig,所以必须开
    fontconfig.enable = true;

    packages = with pkgs; [
      ### 方正字体
      # 方正个人免费字库(含商用免费字体)
      foundertype-gpu-fonts

      # 华为字体(HarmonyOS Sans 全系列)
      harmonyos-sans-fonts

      # 微软字体(Windows 11 zh-CN ISO 全量)
      windows-fonts

      # Noto 系列字体(Google 主导),只装彩色 emoji,思源已经覆盖 CJK
      noto-fonts-color-emoji # 彩色的表情符号字体

      # 思源系列字体(Adobe + Google 共同开发),CJK + 拉丁字符 fallback 链主力
      source-han-sans # 思源黑体
      source-han-serif # 思源宋体

      # nerdfonts:图标 + 等宽,terminal/IDE 必备
      # https://github.com/NixOS/nixpkgs/blob/nixos-unstable-small/pkgs/data/fonts/nerd-fonts/manifests/fonts.json
      nerd-fonts.hack # 主等宽(kmscon/alacritty/GTK fallback)
    ];

    # user defined fonts
    # the reason there's Noto Color Emoji everywhere is to override DejaVu's
    # B&W emojis that would sometimes show instead of some Color emojis
    fontconfig.defaultFonts = {
      serif = [
        "Source Han Serif SC"
        "Source Han Serif TC"
        "Noto Color Emoji"
      ];
      sansSerif = [
        "Source Han Sans SC"
        "Source Han Sans TC"
        "Noto Color Emoji"
      ];
      monospace = [
        "JetBrainsMono Nerd Font"
        "Noto Color Emoji"
      ];
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
      # 字体名走 fontconfig,nerd-fonts.hack 已加进 fonts.packages
      # font-size 在 hosts/wujie/default.nix 按本机分辨率覆盖(2K / 2560×1440)
      font-name = "Hack Nerd Font";
      # Whether to use 3D hardware acceleration to render the console.
      hwaccel = true;
    };
  };
}
