{
  config,
  pkgs,
  myvars,
  ...
}: {
  home.activation = {
    createMountDirectories = config.lib.dag.entryAfter [ "install-packages" ] ''
      # 创建 webdav123 目录
      if [ ! -d "/home/${myvars.username}/Projects/webdav123" ]; then
        echo "Creating webdav123 directory..."
        mkdir -p "/home/${myvars.username}/Projects/webdav123"
      fi
      # 确保正确的所有权和权限
      chown ${myvars.username}:users "/home/${myvars.username}/Projects/webdav123" 2>/dev/null || true
      chmod 755 "/home/${myvars.username}/Projects/webdav123" 2>/dev/null || true
    '';
  };
    systemd.user.services.rclone-webdav = {
      Unit = {
        Description = "Rclone WebDAV Mount";
        After = [ "network-online.target" ]; # 确保网络就绪后启动
      };

      Service = {
        Type = "notify";
        ExecStart = "${pkgs.rclone}/bin/rclone mount webdav_123:/webdav/ /home/${myvars.username}/Projects/webdav123 --vfs-cache-mode full";
        ExecStop = "/run/current-system/sw/bin/fusermount -u /home/${myvars.username}/Projects/webdav123";
        Restart = "on-failure";
        RestartSec = "5s";
      };

      Install = {
        WantedBy = [ "default.target" ]; # 用户登录时自动启动
      };
    };

#
#    systemd.user.services.sshfs = {
#      Unit = {
#        Description = "Rclone sshfs Mount";
#        After = [ "network-online.target" ]; # 确保网络就绪后启动
#      };
#
#      Service = {
#        Type = "notify";
#        ExecStart = "${pkgs.rclone}/bin/rclone mount webdav: /home/${myvars.username}/webdav123 --vfs-cache-mode full";
#        ExecStop = "/run/current-system/sw/bin/fusermount -u /home/${myvars.username}/webdav123";
#        Restart = "on-failure";
#        RestartSec = "5s";
#      };
#
#      Install = {
#        WantedBy = [ "default.target" ]; # 用户登录时自动启动
#      };
#    };
}
