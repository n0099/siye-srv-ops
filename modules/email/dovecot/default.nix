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
          dovecot2.settings = {
            protocols = "imap lmtp";
            service = [
              {
                _section.name = "lmtp";
                "unix_listener ${lmtpSocket}" = {
                  mode = "0600";
                  user = "postfix";
                };
              }
            ];
          };
        };
      }
    )
    {
      config.services.dovecot2.settings = {
        # https://doc.dovecot.org/2.3/configuration_manual/home_directories_for_virtual_users/
        # https://doc.dovecot.org/2.3/settings/pigeonhole/#pigeonhole_setting-sieve
        mail_location = "mdbox:~/mdbox";
        mail_home = "/var/mail/%u";
        auth_mechanisms = [ "plain" ]; # https://github.com/NixOS/nixpkgs/blob/19c56ae874977658f33ab06c04520b1848c3e4b7/nixos/modules/services/mail/dovecot.nix#L427
      };
    }
    {
      config =
        { pkgs, ... }:

        {
          environment.systemPackages = [ pkgs.dovecot_pigeonhole_0_5 ]; # https://github.com/NixOS/nixpkgs/blob/6b316287bae2ee04c9b93c8c858d930fd07d7338/nixos/modules/services/mail/dovecot.nix#L168
          services.dovecot2 = {
            # https://doc.dovecot.org/2.3/configuration_manual/sieve/configuration/#basic-configuration
            mailPlugins.perProtocol.lmtp.enable = [ "sieve" ];
            sieve.extensions = [
              "regex"
              "fileinto"
            ];
            settings.service = [
              {
                _section.name = "managesieve-login";
                "inet_listener sieve".port = 4190;
              }
            ];
          };
        };
    }
  ];
}
