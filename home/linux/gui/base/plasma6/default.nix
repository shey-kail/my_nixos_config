# In your Home Manager configuration (e.g., users/fentas/home.nix or a relevant module)
{ pkgs, lib, config, ... }:
let
  ensureSectionInFile = import ../../../../../lib/ensure_config.nix { inherit lib pkgs; };
in {

  home.packages = [
    # Install Krohnkite package
    pkgs.kdePackages.krohnkite

    pkgs.kdePackages.krdc
    pkgs.kdePackages.kdialog

    # kup for file backup
    pkgs.kdePackages.kup
  ];

  # enable kde connect
  # services.kdeconnect.enable = true;

  # Manage KWin's configuration to enable the script
  # 1. COPY your existing ~/.config/kwinrc file into your Nix repo
  #    (e.g., save it as ./dotfiles/kde/kwinrc)
  # 2. Ensure it has something like this inside (verify your file):
  #    [Plugins]
  #    krohnkiteEnabled=true
  # 3. Tell Home Manager to link it:
  # xdg.configFile."kwinrc".source = ./dotfiles/kde/kwinrc; # Adjust source path

  # NOTE: Managing kwinrc this way overwrites the whole file.
  # More advanced merging is possible using home.file.<path>.text and reading/templating,
  # or potentially the experimental plasma.kconfig options, but managing the source
  # file is often the most reliable starting point.

  home.activation.ensurePlasmashellrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/plasmashellrc} ${config.xdg.configHome}/plasmashellrc
  '';

  home.activation.ensureKsmserverrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/ksmserverrc} ${config.xdg.configHome}/ksmserverrc
  '';

  home.activation.ensureKonsolerc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/konsolerc} ${config.xdg.configHome}/konsolerc
  '';

  home.activation.ensureBaloofilerc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/baloofilerc} ${config.xdg.configHome}/baloofilerc
  '';

  home.activation.ensureBaloofileinformationrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/baloofileinformationrc} ${config.xdg.configHome}/baloofileinformationrc
  '';

  home.activation.ensureKactivitymanagerdPluginsrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/kactivitymanagerd-pluginsrc} ${config.xdg.configHome}/kactivitymanagerd-pluginsrc
  '';

  home.activation.ensureKcminputrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/kcminputrc} ${config.xdg.configHome}/kcminputrc
  '';

  home.activation.ensureBreezerc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/breezerc} ${config.xdg.configHome}/breezerc
  '';

  home.activation.ensureGtkrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/gtkrc} ${config.xdg.configHome}/gtkrc
  '';

  home.activation.ensureGtkrc2 = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/gtkrc-2.0} ${config.xdg.configHome}/gtkrc-2.0
  '';

  home.activation.ensureKded5rc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/kded5rc} ${config.xdg.configHome}/kded5rc
  '';

  home.activation.ensureKdeglobals = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/kdeglobals} ${config.xdg.configHome}/kdeglobals
  '';

  home.activation.ensureKglobalshortcutsrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/kglobalshortcutsrc} ${config.xdg.configHome}/kglobalshortcutsrc
  '';

  home.activation.ensureKiorc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/kiorc} ${config.xdg.configHome}/kiorc
  '';

  home.activation.ensureKmenueditrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/kmenueditrc} ${config.xdg.configHome}/kmenueditrc
  '';

  home.activation.ensureKrunnerrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/krunnerrc} ${config.xdg.configHome}/krunnerrc
  '';

  home.activation.ensureKtimezonedrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/ktimezonedrc} ${config.xdg.configHome}/ktimezonedrc
  '';

  home.activation.ensureKwalletrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/kwalletrc} ${config.xdg.configHome}/kwalletrc
  '';

  home.activation.ensureKwinrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/kwinrc} ${config.xdg.configHome}/kwinrc
  '';

  home.activation.ensureKwinrulesrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/kwinrulesrc} ${config.xdg.configHome}/kwinrulesrc
  '';

  home.activation.ensureKxkbrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/kxkbrc} ${config.xdg.configHome}/kxkbrc
  '';

  home.activation.ensurePlasmaDiscoverUpdates = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/PlasmaDiscoverUpdates} ${config.xdg.configHome}/PlasmaDiscoverUpdates
  '';

  home.activation.ensurePlasmarc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/plasmarc} ${config.xdg.configHome}/plasmarc
  '';

  home.activation.ensurePowerdevilrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/powerdevilrc} ${config.xdg.configHome}/powerdevilrc
  '';

  home.activation.ensurePlasmaLocalerc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/plasma-localerc} ${config.xdg.configHome}/plasma-localerc
  '';

  home.activation.ensurePlasmaOrgKdePlasmaDesktop = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/plasma-org.kde.plasma.desktop-appletsrc} ${config.xdg.configHome}/plasma-org.kde.plasma.desktop-appletsrc
  '';

  home.activation.ensurePowermanagementprofilesrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/powermanagementprofilesrc} ${config.xdg.configHome}/powermanagementprofilesrc
  '';

  home.activation.ensureTrolltech = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/Trolltech.conf} ${config.xdg.configHome}/Trolltech.conf
  '';

  home.activation.ensureXsettingsd = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/xsettingsd} ${config.xdg.configHome}/xsettingsd
  '';

  home.activation.ensureGtk3 = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/gtk-3.0}/ ${config.xdg.configHome}/gtk-3.0/
  '';

  home.activation.ensureGtk4 = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/gtk-4.0}/ ${config.xdg.configHome}/gtk-4.0/
  '';

  home.activation.ensureKDE = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/KDE}/ ${config.xdg.configHome}/KDE/
  '';

  home.activation.ensureKdedefaults = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/kdedefaults}/ ${config.xdg.configHome}/kdedefaults/
  '';

  home.activation.ensureKdeOrg = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.rsync}/bin/rsync -avz --chmod=D2755,F744 ${./dotfiles_writable/kde.org}/ ${config.xdg.configHome}/kde.org/
  '';

    #  imports = [
    #    (ensureSectionInFile {
    #      file = "${config.xdg.configHome}/kuprc";
    #      section = "[Plan/1]";
    #      defaultContent = ''
    #        Accumulated usage time=240
    #        Check backups=true
    #        Description=home备份
    #        Destination type=0
    #        Exclude patterns=true
    #        Exclude patterns file path=.git
    #        Filesystem destination path=file:///home/shey/webdav123/wujie/home
    #        Generate recovery info=false
    #        Paths excluded=
    #        Paths included=/home/shey/.local/bin,/home/shey/.zotero,/home/shey/Codes,/home/shey/Documents,/home/shey/Downloads,/home/shey/Games,/home/shey/Music,/home/shey/Pictures,/home/shey/Public,/home/shey/Videos,/home/shey/obsidian_note
    #        Schedule type=1
    #        Show hidden folders=true
    #
    #        
    #      '';
    #    })
    #  ];

}
