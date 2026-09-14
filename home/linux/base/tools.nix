{pkgs, ...}: {
  # Linux Only Packages, not available on Darwin
  home.packages = with pkgs; [
    csvtk
    htop
    steam-run
    lux
    yt-dlp

    scrcpy

    officecli

    # DeepSeek Harness(numtide llm-agents 每日构建,比 NUR so1ve 新)
    # pkgs.llm-agents.dsh 由 overlays 的 llm-agents overlay 提供
    pkgs.llm-agents.dsh
    gimp
  ];
}
