{ lib, ... }:

{
  flake.modules.nixos."containers/email/roundcube".containers.email = lib.mkMerge [
    {
      config =
        { pkgs, ... }:

        {
          services = {
            roundcube = {
              hostName = "n0099.com";
              extraConfig = ''
                $config['support_url'] = 'https://z.n0099.net';
                $config['product_name'] = '四叶伊美尔';
                $config['imap_host'] = 'tls://localhost:143';
                $config['smtp_host'] = 'tls://localhost:587';
              '';
            };
            phpfpm.pools.roundcube.phpPackage = pkgs.php84 |> lib.mkForce; # https://github.com/NixOS/nixpkgs/blob/c8aa8cc00a5cb57fada0851a038d35c08a36a2bb/nixos/modules/services/mail/roundcube.nix#L264
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
                virtualHosts.${cfg.roundcube.hostName}.locations = {
                  # https://github.com/NixOS/nixpkgs/blob/78e34d1667d32d8a0ffc3eba4591ff256e80576e/nixos/modules/services/mail/roundcube.nix#L182-L211
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
