{ pkgs, ... }:
{
  # Linux Only Packages, not available on Darwin
  home.packages = with pkgs; [
    csvtk
    htop
    steam-run
    lux
    yt-dlp

    scrcpy

    pkgs.nur.repos.zerozawa.deepseek-harness
    officecli

    gimp

  ];
}
