{
  flake.modules.nixos."containers/email/postfix" =
    { config, lib, ... }:

    lib.mkMerge [
      (
        let
          smtpPorts = [
            25
            465
            587
          ];
        in
        {
          networking.firewall.allowedTCPPorts = smtpPorts;
          containers.email = {
            n0099.forwardPorts =
              smtpPorts
              |> map (port: {
                containerPort = port;
                hostListenStreams = [ (port |> toString) ];
              });
            config.services.postfix = {
              enableSubmission = true;
              enableSubmissions = true;
              settings.master =
                lib.genAttrs
                  [
                    # https://github.com/NixOS/nixpkgs/blob/3acb677ea67d4c6218f33de0db0955f116b7588c/nixos/modules/services/mail/postfix.nix#L1066-L1123
                    # https://github.com/NixOS/nixpkgs/blob/3acb677ea67d4c6218f33de0db0955f116b7588c/nixos/modules/services/mail/postfix.nix#L371-L395
                    "submission"
                    # https://datatracker.ietf.org/doc/html/rfc8314#section-7.3
                    # https://serverfault.com/questions/1018401/postfix-port-587-activated-by-uncommenting-a-line-in-master-cf-i-see-no-refere/1018407#1018407
                    "submissions"
                  ]
                  (_: {
                    chroot = true;
                  });
            };
          };
        }
      )
      {
        containers.email = lib.mkMerge (
          [
            {
              config.services.postfix = {
                settings.main = {
                  relayhost = [ "smtp.azurecomm.net:587" ];
                  smtp_sasl_auth_enable = true;
                  smtp_sender_dependent_authentication = true;
                  smtp_sasl_tls_security_options = "noanonymous"; # https://www.postfix.org/SASL_README.html#client_sasl_policy
                };
              };
            }
            (
              let
                sasl = config.age.secrets."postfix.sasl".path;
              in
              {
                bindMounts."${sasl}".isReadOnly = true;
                config.services.postfix.settings.main.smtp_sasl_password_maps = "texthash:${sasl}"; # https://discourse.nixos.org/t/porting-my-postfix-gmail-smtp-to-nixos/30286/12
              }
            )
          ]
          ++ [
            {
              config.services.postfix = lib.mkMerge [
                # https://www.postfix.org/postconf.5.html
                {
                  settings.main = {
                    sender_bcc_maps = "inline:{ @n0099.com=n+sent@n0099.com }"; # https://stackoverflow.com/questions/755853/postfix-send-a-copy-of-every-email-to-a-given-email-address/13611467#13611467
                    mailbox_size_limit = 0;
                    recipientDelimiter = "+";
                  };
                }
                (
                  let
                    virtualDomains = [
                      "n0099.com"
                      "n0099.net"
                      "mcbar.club"
                      "simcity.moe"
                    ];
                  in
                  {
                    virtual =
                      (
                        [
                          "z@n0099.net z@n0099.net"
                        ]
                        ++ (virtualDomains |> map (domain: "@${domain} n@n0099.com"))
                      )
                      |> lib.concatStringsSep "\n";
                    config.virtual_mailbox_domains = virtualDomains;
                  }
                )
              ];
            }
          ]
        );
      }
    ];
}
