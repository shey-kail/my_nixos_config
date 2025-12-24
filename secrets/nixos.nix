{
  config,
  pkgs,
  agenix,
  mysecrets,
  myvars,
  ...
}:
let
  high_security = {
    mode = "0600";
    owner = "root";
  };
  user_readable = {
    mode = "0500";
    owner = myvars.username;
  };
  normal = {
    mode = "0600";
    owner = myvars.username;
  };
in
{
  imports = [
    agenix.nixosModules.default
  ];

  config = {
      environment.systemPackages = [
        agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
      ];

      # 如果实在不行，在这个里面写上recovery的路径
      age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" "/home/${myvars.username}/.ssh/id_rsa" ];

      # secrets that are used by all nixos hosts
      age.secrets = {
        # ---------------------------------------------
        # only root can read this file.
        # ---------------------------------------------
        "wujie_private" = {
          file = "${mysecrets}/ssh/wujie_private/ssh_host_ed25519_key.age";
          path = "/etc/ssh/ssh_host_ed25519_key";
          symlink = false;
        }
        // high_security;

        # ---------------------------------------------
        # user can read this file.
        # ---------------------------------------------
        #        "qwen_oauth_creds" = {
        #          file = "${mysecrets}/qwen/oauth_creds.json.age";
        #          path = "/home/${myvars.username}/.qwen/oauth_creds.json";
        #        }
        #        // normal;
        #
        #        "qwen_installation_id" = {
        #          file = "${mysecrets}/qwen/installation_id.age";
        #          path = "/home/${myvars.username}/.qwen/installation_id";
        #        }
        #        // normal;
        #
        #        "gemini_oauth_creds" = {
        #          file = "${mysecrets}/gemini/oauth_creds.json.age";
        #          path = "/home/${myvars.username}/.gemini/oauth_creds.json";
        #        }
        #        // normal;
        #
        #        "gemini_installation_id" = {
        #          file = "${mysecrets}/gemini/installation_id.age";
        #          path = "/home/${myvars.username}/.gemini/installation_id";
        #        }
        #        // normal;
        #
        #        "gemini_dotenv" = {
        #          file = "${mysecrets}/gemini/dotenv.age";
        #          path = "/home/${myvars.username}/.gemini/.env";
        #        }
        #        // normal;
        #        "gemini_google_accounts" = {
        #          file = "${mysecrets}/gemini/google_accounts.json.age";
        #          path = "/home/${myvars.username}/.gemini/google_accounts.json.age";
        #         }
        #         // normal;

        "shey_private" = {
          file = "${mysecrets}/ssh/shey_private/id_rsa.age";
          path = "/home/${myvars.username}/.ssh/id_rsa";
          symlink = false;
        }
        // user_readable;

        "shey_rclone" = {
          file = "${mysecrets}/rclone/rclone.conf.age";
          path = "/home/${myvars.username}/.config/rclone/rclone.conf";
        }
        // user_readable;

        "singbox_subscriptions" = {
          file = "${mysecrets}/singbox/subscriptions.age";
        }
        // high_security;
      };

      # place secrets in /etc/
      environment.etc = {
        "ssh/ssh_host_ed25519_key" = {
          source = config.age.secrets."wujie_private".path;
          mode = "0600";
          user = "root";
        };
      };
    };
}
