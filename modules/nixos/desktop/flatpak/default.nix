{
  nix-flatpak,
#  inputs,
  lib,
  ...
}: {
  imports = [
    nix-flatpak.nixosModules.nix-flatpak
  ];

  services.flatpak = {
    enable = true;
    remotes = lib.mkOptionDefault [{
      name = "flathub";
      location = "https://mirrors.ustc.edu.cn/flathub/";
    }];
    overrides = {
      global = {
        Environment = {
          # Fix un-themed cursor in some Wayland apps
          XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";

          # Force correct theme for some GTK apps
          GTK_THEME = "Adwaita:dark";
        };
      };
    };
    packages = [
      "com.tencent.wemeet"
      "com.valvesoftware.Steam"
      "org.zotero.Zotero"
      "com.qq.QQ"
      "com.tencent.WeChat"
      "com.baidu.NetDisk"
      "md.obsidian.Obsidian"

    ];
  };
}
