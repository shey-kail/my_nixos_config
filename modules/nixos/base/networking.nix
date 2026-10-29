{
  # Network discovery, mDNS
  # With this enabled, you can access your machine at <hostname>.local
  # it's more convenient than using the IP address.
  # https://avahi.org/
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    # 新 nixpkgs 把 avahi 的发布开关挪到了 settings.publish(原 publish.* 已废弃):
    #   publish.enable       → disable-publishing = false
    #   publish.userServices → disable-user-service-publishing = false + publish-addresses = true
    #   publish.domain       → publish-domain = true
    # 布尔值由模块自动渲染成 avahi 需要的 yes/no。
    settings.publish = {
      disable-publishing = false;
      disable-user-service-publishing = false;
      publish-addresses = true;
      publish-domain = true;
    };
  };

  # Use an NTP server located in the mainland of China to synchronize the system time
  networking.timeServers = [
    "ntp.aliyun.com" # Aliyun NTP Server
    "ntp.tencent.com" # Tencent NTP Server
  ];
}
