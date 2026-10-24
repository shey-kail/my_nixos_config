{
  config,
  lib,
  pkgs,
  ...
}: let
  # ── ArtCraft 系(egui/wgpu)的字体修复 ─────────────────────────────────
  # (1) 中文豆腐块:上游只在硬编码的 FHS 路径里找 CJK 回退字体(crates/text/src/
  #     cjk.rs 的 font_files:/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc
  #     等),而 NixOS 没有 /usr/share/fonts;而且它读 .ttc 时固定取第 0 面,思源
  #     黑体 TTC 的第 0 面是 ExtraLight(细到几乎看不见)。→ 按它探测的路径造出
  #     FHS 别名,主字体用「第 0 面就是 Regular、家族名 Microsoft YaHei 又在它自己
  #     的回退候选表里」的微软雅黑。
  # (2) 字体列表太少:老版本应用(WordCraft 等)的字体库只靠目录扫描,不认
  #     fontconfig → 把系统里所有已安装字体(config.fonts.packages)一并暴露出来。
  # 这棵树由 tmpfiles 链到 /run/host/fonts(见下方说明,不要用 /usr/share/fonts)。
  winFonts = "${pkgs.windows-fonts}/share/fonts/truetype/microsoft";

  # WPS(Flatpak)的 runtime 自带、但本机系统没装的常用拉丁字体。只加进 ArtCraft
  # 的字体树,不动系统 fonts.packages(你要的是 enableDefaultPackages = false 的极简集)。
  # Caladea/Carlito 是 Cambria/Calibri 的度量兼容替身,Liberation 对应 Times/Arial/Courier。
  craftExtraFonts = [
    pkgs.dejavu_fonts
    pkgs.liberation_ttf
    pkgs.freefont_ttf
    pkgs.caladea
    pkgs.carlito
  ];
  craftFontPackages = lib.unique (config.fonts.packages ++ craftExtraFonts);

  # 同事的公文模板里字体名写的是「方正小标宋简体」,而可用的开源/付费包里只有
  # GBK 版(家族名 方正小标宋_GBK / FZXiaoBiaoSong-B05)。Flatpak 沙箱内的
  # fontconfig 不读宿主配置(flatpak 不挂 /etc/fonts,runtime 的 fonts.conf 也只
  # include conf.d),所以别名规则进不去沙箱——唯一的办法是让字体文件自己认这个名字:
  # 复制该字体,在 name 表里**追加**「方正小标宋简体」(nameID 1/4/16),字形不动。
  # 效果:同一份字形同时应答 FZXiaoBiaoSong-B05、方正小标宋_GBK、方正小标宋简体。
  craftXiaoBiaoSongCompat = let
    aliasScript = pkgs.writeText "fzxiaobiaosong-alias.py" ''
      import sys
      from fontTools.ttLib import TTFont
      from fontTools.ttLib.tables._n_a_m_e import NameRecord

      src, dst = sys.argv[1], sys.argv[2]
      font = TTFont(src)
      name = font["name"]
      for lang in (0x409, 0x804):
          for nid in (1, 4, 16):
              rec = NameRecord()
              rec.nameID, rec.platformID, rec.platEncID, rec.langID = nid, 3, 1, lang
              rec.string = "方正小标宋简体".encode("utf-16-be")
              name.names.append(rec)
      font["name"] = name
      font.save(dst)
    '';
  in
    pkgs.runCommand "fzxiaobiaosong-compat" {
      nativeBuildInputs = [(pkgs.python3.withPackages (ps: [ps.fonttools]))];
    } ''
      mkdir -p $out/share/fonts/truetype/foundertype
      python3 ${aliasScript} \
        ${pkgs.foundertype-paid-fonts}/share/fonts/truetype/foundertype/FZXBSK.TTF \
        $out/share/fonts/truetype/foundertype/FZXBSK-compat.ttf
    '';

  craftFhsFonts = pkgs.runCommand "artcraft-fonts" {} ''
    # (2) 全部已安装字体:每个包的 share/fonts 单独链进来(各自子目录,避免同名冲突)
    mkdir -p $out/share/fonts
    for pkg in ${lib.concatStringsSep " " (map builtins.toString craftFontPackages)}; do
      [ -d "$pkg/share/fonts" ] || continue
      name="$(basename "$pkg")"
      rm -f "$out/share/fonts/$name"
      ln -s "$pkg/share/fonts" "$out/share/fonts/$name"
    done

    # (1) ArtCraft 硬编码探测的 FHS 别名
    mkdir -p $out/opentype/noto $out/truetype/wqy $out/truetype/droid $out/truetype/nanum
    # 源字体缺失时让构建直接失败,而不是留下悬空软链(那会静默退回豆腐块)
    linkFont() {
      test -f "$1" || { echo "artcraft-fonts: missing font $1" >&2; exit 1; }
      ln -s "$1" "$2"
    }
    # CJK 四个脚本共用的首选条目(face 0 = Microsoft YaHei Regular)
    linkFont ${winFonts}/msyh.ttc $out/opentype/noto/NotoSansCJK-Regular.ttc
    linkFont ${winFonts}/msyh.ttc $out/truetype/wqy/wqy-microhei.ttc
    # 韩文 / 最后兜底(face 0 = Malgun Gothic Regular)
    linkFont ${winFonts}/malgun.ttf $out/truetype/droid/DroidSansFallbackFull.ttf
    linkFont ${winFonts}/malgun.ttf $out/truetype/nanum/NanumGothic.ttf
  '';
in {
  # fontDir 必须保持开启:生成 /run/current-system/sw/share/X11/fonts,
  # nixpkgs 的 flatpak 补丁(fix-fonts-icons.patch)会把该目录 + 其指向的
  # /nix/store 字体绑进沙箱的 /run/host/fonts —— 这是 WPS 这类 Flatpak 应用
  # 看到宿主字体的**唯一**通道。反过来,一旦宿主上出现 /usr/share/fonts,
  # 补丁会走另一条 else-if 分支、用它顶替掉整个 X11/fonts,宿主字体反而全丢。
  fonts = {
    # use fonts specified by user rather than default ones
    enableDefaultPackages = false;
    fontDir.enable = true;

    # kmscon.config.font-name 走 fontconfig,所以必须开
    fontconfig.enable = true;

    packages = with pkgs; [
      ### 方正字体
      # 方正个人免费字库(含商用免费字体:书宋/楷体/仿宋/黑体)
      foundertype-gpu-fonts

      # 方正付费字库(公文标题标准字体方正小标宋 FZXiaoBiaoSong-B05,
      # 另含隶书/细黑/细圆/准圆/粗圆;来自 office-fonts flake)
      foundertype-paid-fonts

      # 上面那款的兼容副本:让「方正小标宋简体」这个名字也能命中(见 let 块注释)
      craftXiaoBiaoSongCompat

      # 华为字体(HarmonyOS Sans 全系列)
      harmonyos-sans-fonts

      # 微软字体(Windows 11 zh-CN ISO 全量)
      windows-fonts

      # 公文国标字体(GB/T 9704-2012:仿宋_GB2312 / 楷体_GB2312)
      # 来自 office-fonts flake(基于 chinese-fonts-overlay,overlay 已注册进 pkgs)
      office-fonts

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

  # ArtCraft(PhotoCraft/VectorCraft/FilmCraft 等)按 FHS 路径找 CJK 回退字体,
  # 见上面的 craftFhsFonts。它探测两条路径:/usr/share/fonts/<…> 及其 Flatpak
  # 镜像 /run/host/fonts/<…>。这里只用后者:Flatpak 会把**宿主的** /usr/share/fonts
  # 挂进沙箱的 /run/host/fonts,用前者会连带改掉 WPS 等 Flatpak 应用的字体匹配
  # (实测 WPS 365 的 UI 字体被换)。宿主的 /run/host/fonts 不会被挂进沙箱。
  # 第一行顺带清掉早先误建在 /usr/share/fonts 的链接。
  systemd.tmpfiles.rules = [
    "r /usr/share/fonts"
    "L+ /run/host/fonts - - - - ${craftFhsFonts}"
  ];

  # https://wiki.archlinux.org/title/KMSCON
  services.kmscon = {
    # Use kmscon as the virtual console instead of gettys.
    # It's a kms/dri-based userspace virtual terminal implementation.
    # It supports a richer feature set than the linux console VT,
    # including full unicode support, and when the video card supports drm should be much faster.
    enable = true;
    extraOptions = "--term xterm-256color";
    config = {
      # 字体名走 fontconfig,nerd-fonts.hack 已加进 fonts.packages
      # font-size 在 hosts/wujie/default.nix 按本机分辨率覆盖(2K / 2560×1440)
      font-name = "Hack Nerd Font";
      # Whether to use 3D hardware acceleration for the console.
      hwaccel = true;
    };
  };
}
