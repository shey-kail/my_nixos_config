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

}
