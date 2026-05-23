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

    pkgs.nur.repos.lonerOrz.gemini-cli-bin
    pkgs.nur.repos.lonerOrz.qwen-code-bin
    claude-code
    # antigravity

    gimp

  ];
}
