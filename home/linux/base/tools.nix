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

    officecli

    pkgs.nur.repos.so1ve.deepseek-harness
    gimp

  ];
}
