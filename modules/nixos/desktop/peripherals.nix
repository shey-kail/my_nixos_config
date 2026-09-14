{pkgs, ...}: let
  # 打印机私有驱动(佳能 UFR II / 得力 GDI),来自 printer-drivers overlay(pkgs.canon-ufr2 / pkgs.deli-a111)
  printerDrivers = [
    pkgs.canon-ufr2
    pkgs.deli-a111
  ];
in {
  #============================= Audio(PipeWire) =======================

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    pulseaudio # provides `pactl`, which is required by some apps(e.g. sonic-pi)
  ];

  # PipeWire is a new low-level multimedia framework.
  # It aims to offer capture and playback for both audio and video with minimal latency.
  # It support for PulseAudio-, JACK-, ALSA- and GStreamer-based applications.
  # PipeWire has a great bluetooth support, it can be a good alternative to PulseAudio.
  #     https://nixos.wiki/wiki/PipeWire
  services.pipewire = {
    enable = true;
    # package = pkgs-unstable.pipewire;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;
    wireplumber.enable = true;
  };
  # rtkit is optional but recommended
  security.rtkit.enable = true;
  # Disable pulseaudio, it conflicts with pipewire too.
  services.pulseaudio.enable = false;

  #============================= Bluetooth =============================

  # hardware.bluetooth.enable = true;
  # services.blueman.enable = true;

  #================================= Misc =================================

  services = {
    # CUPS 打印服务
    printing = {
      enable = true;
      # cups-browsed:自动发现局域网打印机(Deli M2000DNW 等 IPP/dnssd 设备)
      browsing = true;
      # 让 CUPS 找到私有驱动的 PPD / 滤镜
      drivers = printerDrivers;
    };
    geoclue2.enable = true; # Enable geolocation services.
  };
}
