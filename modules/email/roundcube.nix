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
              extraConfig = /* php_only */ ''
                $config['support_url'] = 'https://z.n0099.net';
                $config['product_name'] = '四叶伊美尔';
                $config['imap_host'] = 'tls://localhost:143';
                $config['smtp_host'] = 'tls://localhost:587';
              '';
            };
            phpfpm = {
              pools.roundcube.phpPackage = pkgs.php85 |> lib.mkForce; # TODO: remove when reach `nixos-26.11`: https://github.com/NixOS/nixpkgs/pull/575759/changes/1d251f39b495366fcb04ff1b3543d2b22af032fa
              phpOptions = ''
                ; https://github.com/n0099/siye-srv-ops/blob/727477fce471e23f097e1aa437127b477e50bfbe/base/s6.nginx.php-fpm/php/php-fpm-fcgi.ini
                error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
                display_errors = Off
                allow_url_fopen = Off
                expose_php = Off
                disable_functions = putenv,create_function,disk_free_space,disk_total_space,diskfreespace,dl,eval,exec,get_current_user,getlastmo,getmygid,getmyinode,getmypid,getmyuid,mail,mb_send_mail,opcache_get_configuration,opcache_get_status,passthru,pclose,pcntl_alarm,pcntl_async_signals,pcntl_exec,pcntl_fork,pcntl_get_last_error,pcntl_getpriority,pcntl_setpriority,pcntl_signal,pcntl_signal_dispatch,pcntl_signal_get_handler,pcntl_sigprocmask,pcntl_sigtimedwait,pcntl_sigwaitinfo,pcntl_strerror,pcntl_unshare,pcntl_wait,pcntl_waitpid,pcntl_wexitstatus,pcntl_wifcontinued,pcntl_wifexited,pcntl_wifsignaled,pcntl_wifstopped,pcntl_wstopsig,pcntl_wtermsig,php_ini_loaded_file,phpinfo,popen,posix_getlogin,posix_getpwuid,posix_kill,posix_mkfifo,posix_setpgid,posix_setsid,posix_setuid,posix_ttyname,posix_uname,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,shell_exec,show_source,system ; https://github.com/HackTricks-wiki/hacktricks/blob/dedebe9da3b6568f28b1c9b6c7990208e99ad068/src/network-services-pentesting/pentesting-web/php-tricks-esp/php-useful-functions-disable_functions-open_basedir-bypass/README.md#other-interesting-php-functions
                output_buffering = 4096
                max_execution_time = 60
                post_max_size = 16M
                upload_max_filesize = 16M
                fastcgi.logging = Off ; https://stackoverflow.com/questions/77426003/symfony-nginx-upstream-sent-too-big-header-while-reading-response-header-fro/79031358#79031358
                session.upload_progress.enabled = Off ; TODO: remove when CVE-2026-115560 get fixed: https://www.php.net/archive/2026.php#2026-10-23-1
                ; TODO: remove when reach PHP 8.6: https://wiki.php.net/rfc/session_security_defaults
                session.use_strict_mode = On
                session.cookie_httponly = On
                session.cookie_samesite = Lax
              '';
            };
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
        { config, ... }:

        let
          cfg = config.services;
          subBaseDir = "/rc";
          root = "/srv/www";
          alias = "${root}${subBaseDir}";
        in
        {
          networking.firewall.allowedTCPPorts = [ 80 ];
          systemd.tmpfiles.settings."www-root".${alias}."L+".argument = cfg.roundcube.package.outPath;
          services = {
            roundcube.configureNginx = false;
            # https://github.com/NixOS/nixpkgs/blob/4ad7c2e156dc34bcb0c4a3dcf7adadd3ef539e51/nixos/modules/services/mail/roundcube.nix#L240-L244
            phpfpm.pools.roundcube.phpOptions = lib.mkForce ''
              open_basedir = /tmp:/nix/store:/run/agenix:/var/lib/roundcube/des_key:${alias}
            '';
            nginx = {
              enable = true;
              virtualHosts."${cfg.roundcube.hostName}" = {
                # https://github.com/calops/hmts.nvim/issues/36
                inherit root;
                locations."${subBaseDir}/" = lib.mkMerge [
                  {
                    index = "index.php";
                  }
                  {
                    # https://github.com/n0099/siye-srv-ops/blob/cad30264d6f80e5ab1e7adc1581309f75a1d81a4/base/s6.nginx.php-fpm/nginx/templates/sub-base-dir.conf
                    alias = "${alias}/public_html/"; # https://github.com/roundcube/roundcubemail/issues/10160
                    tryFiles = "$uri $uri/ ${subBaseDir}/${subBaseDir}/index.php?$query_string"; # https://stackoverflow.com/questions/20426812/nginx-try-files-alias-directives/35102259#35102259
                    extraConfig = ''
                      # https://github.com/NixOS/nixpkgs/pull/40303
                      location ~ [^/]\.php(/|$) {
                        fastcgi_pass unix:${cfg.phpfpm.pools.roundcube.socket};
                        include ${cfg.nginx.package}/conf/fastcgi_params;

                        # https://github.com/nginxinc/nginx-wiki/blob/4ead66e6363f149e700f9a2ca0340c64a657f8e0/source/start/topics/tutorials/config_pitfalls.rst#use-request_filename-for-script_filename
                        # https://serverfault.com/questions/465607/nginx-document-rootfastcgi-script-name-vs-request-filename/922596#922596
                        fastcgi_param SCRIPT_FILENAME $request_filename;
                      }
                    '';
                  }
                ];
              };
            };
          };
        };
    }
  ];
}
