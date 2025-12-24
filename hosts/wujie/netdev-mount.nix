{
  myvars,
  pkgs,
  ...
}: {
  system.fsPackages = [ pkgs.sshfs ];
  # supported file systems, so we can mount any removable disks with these filesystems
  boot.supportedFilesystems = [
    # "cifs"
    # "davfs"
    "sshfs"
  ];
  
  
  # Ensure the datapool directory exists with proper permissions
  systemd.tmpfiles.rules = [
    "d /datapool/home/2023200498 0777 root users - -"
  ];

  # mount a smb/cifs share
  # fileSystems."/home/${myvars.username}/SMB-Downloads" = {
  #   device = "//windows-server-nas/Downloads";
  #   fsType = "cifs";
  #   options = [
  #     # https://www.freedesktop.org/software/systemd/man/latest/systemd.mount.html
  #     "nofail,_netdev"
  #     "uid=1000,gid=100,dir_mode=0755,file_mode=0755"
  #     "vers=3.0,credentials=${config.age.secrets.smb-credentials.path}"
  #   ];
  # };

  # # mount a webdav share
  # # https://wiki.archlinux.org/title/Davfs2
  # fileSystems."/home/${myvars.username}/webdav_123" = {
  #   device = "https://webdav-1818881235.pd1.123pan.cn/webdav";
  #   fsType = "davfs";
  #   options = [
  #     # https://www.freedesktop.org/software/systemd/man/latest/systemd.mount.html
  #     "nofail,_netdev"
  #     "uid=1000,gid=100,dir_mode=0755,file_mode=0755"
  #   ];
  # };
  # # davfs2 reads its credentials from /etc/davfs2/secrets
  # environment.etc."davfs2/secrets".source = ./dotfiles/davfs2/secrets;

#  # sshfs
#  fileSystems."/datapool/home/2023200498" = {
#    device = "2023200498@10.68.162.201:/datapool/home/2023200498";
#    fsType = "sshfs";
#    options = [
#      "nodev"
#      "noatime"
#      "allow_other"
#      "idmap=user"
#      "_netdev"
#      "x-systemd.automount"
#      "x-systemd.idle-timeout=600"
#      "port=22"
#      "IdentityFile=/home/${myvars.username}/.ssh/id_rsa"
#    ];
#  };
#  
#  services.openssh.knownHosts = {
#    ds920 = {
#      hostNames = [
#        "ds920.local"
#      ];
#      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHLn9ETNjjj49yGV+0xTmbD4oWYXXGWYn96Kn9ZT0lAC";
#    };
#  };
}
