{
  config,
  lib,
  inputs,
  ...
}:

{
  containers.email = lib.mkMerge [
    {
      subnetPrefix = "172.16.0.";
      bindMounts."/var/spool/mail" = {
        hostPath = "/srv/mail";
        isReadOnly = false;
      };
      forwardPorts = lib.map (port: lib.genAttrs [ "containerPort" "hostPort" ] (_: port)) [ 25 ];
      config.services = {
        # https://brokkr.net/2018/06/04/setting-up-postfix-and-dovecot-slowly-and-properly/
        postfix.enable = true;
        dovecot2.enable = true;
      };
    }
    (
      let
        certDir = "/etc/ssl/certs/n0099.net";
      in
      {
        bindMounts.${certDir}.isReadOnly = true;
        config.services = {
          postfix = {
            sslCert = "${certDir}/cert.pem";
            sslKey = "${certDir}/privkey.pem";
            config = {
              # https://utcc.utoronto.ca/~cks/space/blog/spam/TLSExternalTypes-2025-05
              lmtp_tls_protocols = ">=TLSv1.3";
              smtp_tls_protocols = ">=TLSv1.3";
              smtpd_tls_protocols = ">=TLSv1.2";
            };
          };
          dovecot2 = {
            sslServerCert = "${certDir}/cert.pem";
            sslServerKey = "${certDir}/privkey.pem";
            extraConfig = ''
              # https://doc.dovecot.org/2.3/configuration_manual/dovecot_ssl_configuration/
              ssl = required
              ssl_min_protocol = TLSv1.3
            '';
          };
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
    (
      let
        lmtpSocket = "/run/dovecot-lmtp";
      in
      {
        config.services = {
          postfix.config.virtual_transport = "lmtp:unix:${lmtpSocket}";
          dovecot2 = {
            enableLmtp = true;
            extraConfig = ''
              service lmtp {
                unix_listener ${lmtpSocket} {
                  mode = 0600
                  user = postfix
                  group = postfix
                }
              }
            '';
          };
        };
      }
    )
    {
      config.services.dovecot2 = {
        mailLocation = "mdbox:/var/mail/%u/mdbox";
        extraConfig = ''
          auth_mechanisms = plain # https://doc.dovecot.org/2.3/configuration_manual/authentication/#authentication-in-proxies-and-directors
        '';
      };
    }
    {
      bindMounts."/var/lib/dhparams/dovecot2.pem".isReadOnly = false;
      config = {
        services.dovecot2.enableDHE = true;
        systemd.services.dhparams-gen-dovecot2.requiredBy = [ "dovecot2.service" ]; # https://github.com/NixOS/nixpkgs/pull/453845
      };
    }
    {
      config.services.dovecot2 = {
        # https://doc.dovecot.org/2.3/settings/core/
        mailPlugins.perProtocol.lmtp.enable = [ "sieve" ];
        extraConfig = ''
          service managesieve-login {
            inet_listener sieve {
              port = 4190
            }
          }
        '';
      };
    }
    (
      let
        mysqlSocket = "/run/mysqld/mysqld.sock";
      in
      lib.mkMerge [
        { bindMounts.${mysqlSocket}.isReadOnly = true; }
        (
          let
            hostPrivateKey = "/etc/ssh/ssh_host_ed25519_key";
            secretName = "roundcube.db.password";
          in
          {
            bindMounts."${hostPrivateKey}".isReadOnly = true;
            config =
              { ... }@container:

              {
                # https://wiki.nixos.org/wiki/Agenix#Access_secrets_inside_a_container
                imports = [ inputs.agenix.nixosModules.default ];
                age = {
                  identityPaths = [ hostPrivateKey ];
                  secrets.${secretName} = {
                    file = ../secrets/roundcube.db.password.age;
                    symlink = false;
                    owner = "nginx";
                  };
                };
                services.roundcube.database = {
                  host = "unix(${mysqlSocket})";
                  passwordFile = container.config.age.secrets.${secretName}.path;
                };
              };
          }
        )
        (
          let
            dbConnect = config.age.secrets."dovecot.db.connect".path;
          in
          {
            bindMounts."${dbConnect}".isReadOnly = true;
            config =
              let
                sqlArgsFile = "dovecot-sql.conf.ext";
              in
              {
                services.dovecot2.extraConfig = ''
                  passdb {
                    driver = sql
                    args = ${sqlArgsFile}
                  }
                  userdb {
                    driver = sql
                    args = ${sqlArgsFile}
                  }'';
                environment.etc."dovecot/${sqlArgsFile}".text = ''
                  !include ${dbConnect}
                  driver = mysql
                  default_pass_scheme = ARGON2ID
                  user_query = \
                    SELECT username \
                    FROM dovecot_users WHERE username = '%n' AND domain = '%d'
                  password_query = \
                    SELECT username, domain, password \
                    FROM dovecot_users WHERE username = '%n' AND domain = '%d'
                  iterate_query = SELECT username AS user FROM dovecot_users
                '';
              };
          }
        )
      ]
    )
    {
      config =
        { pkgs, ... }@container:

        {
          services.roundcube = rec {
            enable = true;
            database = {
              dbname = "email";
              username = "email";
            };
            hostName = "n0099.net";
            extraConfig = ''
              $config['db_dsnw'] = preg_replace('#^pgsql://#', 'mysql://', $config['db_dsnw']);
              $config['db_prefix'] = 'roundcube_';
              $config['imap_host'] = 'tls://localhost:143';
              $config['imap_conn_options']['ssl']['peer_name'] ='${hostName}';
              $config['smtp_host'] = 'tls://localhost:587';
              $config['smtp_conn_options']['ssl']['peer_name'] ='${hostName}';
              $config['support_url'] = 'https://z.n0099.net';
              $config['product_name'] = '四叶伊美尔';
            '';
          };
          services.nginx.virtualHosts.${container.config.services.roundcube.hostName} = {
            # https://github.com/NixOS/nixpkgs/blob/c8aa8cc00a5cb57fada0851a038d35c08a36a2bb/nixos/modules/services/mail/roundcube.nix#L180-L181
            forceSSL = false;
            enableACME = false;
          };
          services.phpfpm.pools.roundcube.phpPackage = lib.mkForce pkgs.php84; # https://github.com/NixOS/nixpkgs/blob/c8aa8cc00a5cb57fada0851a038d35c08a36a2bb/nixos/modules/services/mail/roundcube.nix#L264
          systemd.services = {
            # https://github.com/NixOS/nixpkgs/blob/c8aa8cc00a5cb57fada0851a038d35c08a36a2bb/nixos/modules/services/mail/roundcube.nix#L274
            roundcube-setup.enable = false;
            roundcube-generate-des-key = {
              # https://github.com/NixOS/nixpkgs/blob/c8aa8cc00a5cb57fada0851a038d35c08a36a2bb/nixos/modules/services/mail/roundcube.nix#L267-L272
              before = [ "phpfpm-roundcube.service" ];
              requiredBy = [ "phpfpm-roundcube.service" ];
              serviceConfig = {
                # https://github.com/NixOS/nixpkgs/blob/c8aa8cc00a5cb57fada0851a038d35c08a36a2bb/nixos/modules/services/mail/roundcube.nix#L308-L314
                Type = "oneshot";
                User = "nginx";
                StateDirectory = "roundcube";
                StateDirectoryMode = "0700";
              };
            }
            // (
              let
                path = "/var/lib/roundcube/des_key";
              in
              {
                script = ''
                  # https://github.com/NixOS/nixpkgs/blob/c8aa8cc00a5cb57fada0851a038d35c08a36a2bb/nixos/modules/services/mail/roundcube.nix#L299-L304
                  base64 /dev/urandom | head -c 24 > ${path}
                '';
                unitConfig.ConditionFileNotEmpty = "!${path}";
              }
            );
          };
        };
    }
  ];
}
