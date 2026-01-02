{ lib, ... }:

{
  flake.modules.nixos."containers/email/dovecot".containers.email = lib.mkMerge [
    (
      let
        lmtpSocket = "/run/dovecot-lmtp";
      in
      {
        config.services = {
          postfix.settings.main.virtual_transport = "lmtp:unix:${lmtpSocket}";
          dovecot2 = {
            enableLmtp = true;
            extraConfig = ''
              service lmtp {
                unix_listener ${lmtpSocket} {
                  mode = 0600
                  user = postfix
                }
              }
            '';
          };
        };
      }
    )
    {
      config.services.dovecot2 = {
        # https://doc.dovecot.org/2.3/configuration_manual/home_directories_for_virtual_users/
        # https://doc.dovecot.org/2.3/settings/pigeonhole/#pigeonhole_setting-sieve
        mailLocation = "mdbox:~/mdbox";
        extraConfig = ''
          mail_home = /var/mail/%u
          auth_mechanisms = plain login # https://github.com/MoeNetwork/Tieba-Cloud-Sign/issues/295
        '';
      };
    }
    {
      config =
        { pkgs, ... }:

        {
          environment.systemPackages = [ pkgs.dovecot_pigeonhole ];
          services.dovecot2 = {
            # https://doc.dovecot.org/2.3/configuration_manual/sieve/configuration/#basic-configuration
            mailPlugins.perProtocol.lmtp.enable = [ "sieve" ];
            sieve.extensions = [
              "regex"
              "fileinto"
            ];
            extraConfig = ''
              service managesieve-login {
                inet_listener sieve {
                  port = 4190
                }
              }
            '';
          };
        };
    }
  ];
}
