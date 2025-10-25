{ config, lib, ... }:

{
  containers.email = lib.mkMerge [
    {
      subnetPrefix = "172.16.0.";
      bindMounts."/var/mail" = {
        hostPath = "/srv/mail";
        isReadOnly = false;
      };
      forwardPorts = lib.map (port: lib.genAttrs [ "containerPort" "hostPort" ] (_: port)) [ 25 ];
      config.services.postfix.enable = true;
    }
    (
      let
        certDir = "/etc/ssl/certs/n0099.net";
      in
      {
        bindMounts.${certDir}.isReadOnly = true;
        config.services.postfix = {
          sslCert = "${certDir}/cert.pem";
          sslKey = "${certDir}/privkey.pem";
        };
      }
    )
    {
      config.services.postfix = lib.mkMerge (
        [
          # https://www.postfix.org/postconf.5.html
          {
            hostname = "n0099.net";
            destination = [
              "localhost.$mydomain"
              "localhost"
            ];
            config.sender_bcc_maps = "inline:{ @n0099.net=n+sent@n0099.net }"; # https://stackoverflow.com/questions/755853/postfix-send-a-copy-of-every-email-to-a-given-email-address/13611467#13611467
          }
          {
            networks = [
              "172.16.0.0/12"
              "127.0.0.0/8"
              "[::ffff:127.0.0.0]/104"
              "[::1]/128"
            ];
            config.mailbox_size_limit = 0;
            recipientDelimiter = "+";
          }
          (
            let
              virtualDomains = [
                "n0099.net"
                "mcbar.club"
                "simcity.moe"
              ];
            in
            {
              virtual =
                "z@n0099.net z@n0099.net"
                + lib.concatMapStringsSep "\n" (domain: "@${domain} n@n0099.net") virtualDomains;
              config.virtual_mailbox_domains = virtualDomains;
            }
          )
        ]
        ++ [
          {
            lookupMX = true;
            relayHost = "smtp.azurecomm.net";
            relayPort = 587;
            config = {
              smtp_sasl_auth_enable = true;
              smtp_sender_dependent_authentication = true;
            };
          }
          {
            config = {
              tls_append_default_CA = true;
              smtp_tls_session_cache_database = "btree:\${data_directory}/smtp_scache";
              smtp_tls_security_level = "dane";
              smtp_dns_support_level = "dnssec";
            };
          }
        ]
        ++ [
          {
            config.smtpd_tls_received_header = true;
            config.smtpd_relay_restrictions = "permit_mynetworks permit_sasl_authenticated defer_unauth_destination reject_unknown_recipient_domain reject_unverified_recipient";
          }
        ]
      );
    }
    (
      let
        sasl = config.age.secrets."postfix.sasl".path;
      in
      {
        bindMounts."${sasl}".isReadOnly = true;
        config.services.postfix.config.smtp_sasl_password_maps = "texthash:${sasl}"; # https://discourse.nixos.org/t/porting-my-postfix-gmail-smtp-to-nixos/30286/12
      }
    )
  ];
}
