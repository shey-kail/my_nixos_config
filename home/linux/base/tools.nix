{ pkgs, ...}: {
  # Linux Only Packages, not available on Darwin
  home.packages = with pkgs; [
    virt-viewer # vnc connect to VM, used by kubevirt

    csvtk
    htop
    steam-run
    lux
    python313Packages.markitdown
    yt-dlp

    scrcpy

    pkgs.nur.repos.lonerOrz.gemini-cli-bin
    pkgs.nur.repos.lonerOrz.qwen-code

  ];
}
