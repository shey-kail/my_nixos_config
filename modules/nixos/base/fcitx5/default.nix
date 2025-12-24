{
  pkgs,
  ...
}: {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [
        # fcitx5-configtool
        qt6Packages.fcitx5-configtool
        qt6Packages.fcitx5-chinese-addons
        fcitx5-gtk # gtk im module
        # fcitx5 dictionary
        fcitx5-pinyin-zhwiki
        libsForQt5.fcitx5-qt
        fcitx5-table-other
        fcitx5-lua
      ];
      waylandFrontend = true;
    };
  };
}
