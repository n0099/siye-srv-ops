{
  config,
  lib,
  inputs,
  ...
}:

let
  smtpPorts = [
    25
    465
    587
  ];
in
lib.mkMerge [
  {
    networking.firewall.allowedTCPPorts = smtpPorts;
    containers.email = lib.mkMerge [
      {
        n0099 = {
          subnetPrefix = "172.16.0.";
          forwardPorts = lib.map (port: {
            containerPort = port;
            hostListenStreams = [ (builtins.toString port) ];
          }) smtpPorts;
          outboundInterface = "ens3";
        };
        bindMounts."/var/spool/mail" = {
          hostPath = "/srv/mail";
          isReadOnly = false;
        };
        config.services = {
          # https://brokkr.net/2018/06/04/setting-up-postfix-and-dovecot-slowly-and-properly/
          postfix.enable = true;
          dovecot2.enable = true;
        };
      }
      (
        let
          cert = rec {
            dir = "/etc/ssl/certs/n0099.net";
            cert = "${dir}/fullchain.pem";
            privateKey = "${dir}/privkey.pem";
          };
        in
        {
          bindMounts.${cert.dir}.isReadOnly = true;
          config.services = {
            postfix = {
              sslCert = cert.cert;
              sslKey = cert.privateKey;
              config = {
                # https://utcc.utoronto.ca/~cks/space/blog/spam/TLSExternalTypes-2025-05
                lmtp_tls_protocols = ">=TLSv1.3";
                smtp_tls_protocols = ">=TLSv1.3";
                smtpd_tls_protocols = ">=TLSv1.2";
              };
            };
            dovecot2 = {
              sslServerCert = cert.cert;
              sslServerKey = cert.privateKey;
              extraConfig = ''
                # https://doc.dovecot.org/2.3/configuration_manual/dovecot_ssl_configuration/
                ssl = required
                ssl_min_protocol = TLSv1.3
              '';
            };
            roundcube.extraConfig =
              let
                commonName = "n0099.net";
              in
              ''
                # https://www.roundcubeforum.net/index.php?topic=22035.0
                $config['imap_conn_options']['ssl']['peer_name'] ='${commonName}';
                $config['smtp_conn_options']['ssl']['peer_name'] ='${commonName}';
              '';
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
                virtual = lib.concatStringsSep "\n" (
                  [
                    "z@n0099.net z@n0099.net"
                  ]
                  ++ lib.map (domain: "@${domain} n@n0099.net") virtualDomains
                );
                config.virtual_mailbox_domains = virtualDomains;
              }
            )
          ]
          ++ [
            {
              relayHost = "smtp.azurecomm.net";
              relayPort = 587;
              config = {
                smtp_sasl_auth_enable = true;
                smtp_sender_dependent_authentication = true;
                smtp_sasl_tls_security_options = "noanonymous"; # https://www.postfix.org/SASL_README.html#client_sasl_policy
              };
            }
            {
              config = {
                tls_append_default_CA = true;
                smtp_tls_session_cache_database = "btree:\${data_directory}/smtp_scache";
              };
            }
          ]
          ++ [
            {
              config = {
                smtpd_tls_received_header = true;
                smtpd_relay_restrictions = "permit_mynetworks permit_sasl_authenticated defer_unauth_destination reject_unknown_recipient_domain reject_unverified_recipient";
              };
              masterConfig =
                lib.genAttrs
                  [
                    # https://datatracker.ietf.org/doc/html/rfc8314#section-7.3
                    "smtps"
                    "submission"
                  ]
                  (_: {
                    # https://serverfault.com/questions/1018401/postfix-port-587-activated-by-uncommenting-a-line-in-master-cf-i-see-no-refere/1018407#1018407
                    type = "inet";
                    private = false;
                    chroot = true;
                    command = "smtpd";
                  });
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
          # https://doc.dovecot.org/2.3/configuration_manual/home_directories_for_virtual_users/
          # https://doc.dovecot.org/2.3/settings/pigeonhole/#pigeonhole_setting-sieve
          mailLocation = "mdbox:~/mdbox";
          extraConfig = ''
            mail_home = /var/mail/%u
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
      {
        config =
          { pkgs, ... }:

          {
            services = {
              roundcube = {
                enable = true;
                hostName = "n0099.net";
                extraConfig = ''
                  $config['support_url'] = 'https://z.n0099.net';
                  $config['product_name'] = '四叶伊美尔';
                  $config['imap_host'] = 'tls://localhost:143';
                  $config['smtp_host'] = 'tls://localhost:587';
                  # https://github.com/roundcube/roundcubemail/blob/2ae7cec1ca7086a93500f05b3810f2cc9a16990f/config/defaults.inc.php#L273-L281
                  $config['smtp_user'] = "";
                  $config['smtp_pass'] = "";
                '';
              };
              phpfpm.pools.roundcube.phpPackage = lib.mkForce pkgs.php84; # https://github.com/NixOS/nixpkgs/blob/c8aa8cc00a5cb57fada0851a038d35c08a36a2bb/nixos/modules/services/mail/roundcube.nix#L264
            };
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
      {
        config =
          { ... }@container:

          let
            cfg = container.config.services;
          in
          lib.mkMerge [
            {
              networking.firewall.allowedTCPPorts = [ 80 ];
              services = {
                roundcube.configureNginx = false;
                nginx = {
                  enable = true;
                  virtualHosts.${cfg.roundcube.hostName} = {
                    # https://github.com/NixOS/nixpkgs/blob/78e34d1667d32d8a0ffc3eba4591ff256e80576e/nixos/modules/services/mail/roundcube.nix#L182-L211
                    locations = {
                      "/rc/" = {
                        index = "index.php";
                        priority = 1100;
                        extraConfig = ''
                          add_header Cache-Control 'public, max-age=604800, must-revalidate';
                        '';
                      };
                      # https://github.com/NixOS/nixpkgs/pull/276496/files#r1438374310
                      # https://wiki.archlinux.org/title/Roundcube#Webserver_(Nginx)
                      "~ ^/rc/(SQL|bin|config|logs|temp|vendor)/" = {
                        priority = 3110;
                        return = 404;
                      };
                      "~ ^/rc/(CHANGELOG.md|INSTALL|LICENSE|README.md|SECURITY.md|UPGRADING|composer.json|composer.lock)" =
                        {
                          priority = 3120;
                          return = 404;
                        };
                      "~* \\.php(/|$)" = {
                        priority = 3130;
                        extraConfig = ''
                          fastcgi_pass unix:${cfg.phpfpm.pools.roundcube.socket};
                          include ${cfg.nginx.package}/conf/fastcgi_params;
                        '';
                      };
                    };
                  };
                };
              };
            }
            (
              let
                root = "/srv/www";
                alias = "${root}/rc";
              in
              {
                systemd.tmpfiles.settings."www-root".${alias}."L+".argument = cfg.roundcube.package.outPath;
                services.nginx.virtualHosts.${cfg.roundcube.hostName} = {
                  inherit root;
                  locations = {
                    "/rc/".alias = "${alias}/";
                    "~* \\.php(/|$)".extraConfig = ''
                      # https://serverfault.com/questions/465607/nginx-document-rootfastcgi-script-name-vs-request-filename/922596#922596
                      fastcgi_param SCRIPT_FILENAME $request_filename;
                    '';
                  };
                };
              }
            )
          ];
      }
    ];
  }
  {
    systemd.services."container@email" =
      let
        mysql = [ "mysql.service" ];
      in
      {
        after = mysql;
        partOf = mysql; # https://serverfault.com/questions/812492/systemd-automatically-start-restart-specific-systemd-service-after-another-ser
      };
    containers.email =
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
                services.roundcube = {
                  database = {
                    host = "unix(${mysqlSocket})";
                    passwordFile = container.config.age.secrets.${secretName}.path;
                    dbname = "email";
                    username = "email";
                  };
                  extraConfig = ''
                    $config['db_dsnw'] = preg_replace('#^pgsql://#', 'mysql://', $config['db_dsnw']);
                    $config['db_prefix'] = 'roundcube_';
                  '';
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
                sqlArgsFilePath = "dovecot/dovecot-sql.conf.ext";
              in
              {
                nixpkgs.overlays = [
                  (self: super: {
                    # https://github.com/NixOS/nixpkgs/blob/78e34d1667d32d8a0ffc3eba4591ff256e80576e/pkgs/by-name/do/dovecot/package.nix#L37
                    # https://github.com/NixOS/nixpkgs/pull/14898
                    dovecot = super.dovecot.override { withMySQL = true; };
                  })
                ];
                services.dovecot2.extraConfig = ''
                  passdb {
                    driver = sql
                    args = /etc/${sqlArgsFilePath}
                  }
                  userdb {
                    driver = sql
                    args = /etc/${sqlArgsFilePath}
                  }
                '';
                environment.etc.${sqlArgsFilePath}.text = ''
                  !include ${dbConnect}
                  driver = mysql
                  default_pass_scheme = ARGON2ID
                  # https://doc.dovecot.org/2.3/admin_manual/system_users_used_by_dovecot/#uids
                  # https://systemd.io/UIDS-GIDS/
                  # https://man.archlinux.org/man/login.defs.5
                  user_query = \
                    SELECT username, uid, gid \
                    FROM dovecot_users WHERE username = '%n' AND domain = '%d'
                  password_query = \
                    SELECT username, domain, password \
                    FROM dovecot_users WHERE username = '%n' AND domain = '%d'
                  iterate_query = SELECT username AS user FROM dovecot_users
                '';
              };
          }
        )
      ];
  }
]
