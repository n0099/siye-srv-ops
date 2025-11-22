{ lib, ... }:

{
  containers.email = lib.mkMerge [
    (
      let
        socketPathChrooted = "private/auth";
        socketPath = "/var/lib/postfix/queue/${socketPathChrooted}"; # https://www.postfix.org/postconf.5.html#queue_directory
      in
      {
        config = {
          services = {
            postfix.config = {
              smtpd_sasl_type = "dovecot";
              smtpd_sasl_path = socketPathChrooted;
            };
            # https://www.postfix.org/SASL_README.html#server_sasl_enable
            dovecot2 = {
              extraConfig = ''
                # https://www.postfix.org/SASL_README.html#server_dovecot
                service auth {
                  unix_listener ${socketPath} {
                    mode = 0600
                    user = postfix
                  }
                }
              '';
            };
          };
          systemd.services.dovecot2 =
            let
              postfix = [ "postfix.service" ];
            in
            {
              after = postfix;
              requires = postfix;
            };
        };
      }
    )
  ];
}
