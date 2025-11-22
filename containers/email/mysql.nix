{
  config,
  lib,
  inputs,
  ...
}:

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
                  file = ../../secrets/roundcube.db.password.age;
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
              genArgsFilePath = type: "dovecot/dovecot-passdb-sql-${type}.conf.ext";
              lmtpArgsFilePath = genArgsFilePath "lmtp";
              authArgsFilePath = genArgsFilePath "auth";
              genConfig = argsFilePath: {
                services.dovecot2.extraConfig = ''
                  passdb {
                    driver = sql
                    args = /etc/${argsFilePath}
                  }
                '';
                environment.etc.${argsFilePath}.text = ''
                  !include ${dbConnect}
                  driver = mysql
                  default_pass_scheme = ARGON2ID # https://doc.dovecot.org/2.3/configuration_manual/authentication/sql/#password-database-lookups
                '';
              };
            in
            lib.mkMerge (
              [
                {
                  nixpkgs.overlays = [
                    (self: super: {
                      # https://github.com/NixOS/nixpkgs/blob/78e34d1667d32d8a0ffc3eba4591ff256e80576e/pkgs/by-name/do/dovecot/package.nix#L37
                      # https://github.com/NixOS/nixpkgs/pull/14898
                      dovecot = super.dovecot.override { withMySQL = true; };
                    })
                  ];
                }
              ]
              ++ [
                (genConfig lmtpArgsFilePath)
                {
                  services.dovecot2.extraConfig = ''
                    userdb {
                      driver = sql
                      args = /etc/${lmtpArgsFilePath}
                    }
                  '';
                  environment.etc.${lmtpArgsFilePath}.text = ''
                    # https://doc.dovecot.org/2.3/admin_manual/system_users_used_by_dovecot/#uids
                    # https://systemd.io/UIDS-GIDS/
                    # https://man.archlinux.org/man/login.defs.5
                    user_query = \
                      SELECT username, uid, gid \
                      FROM dovecot_passdb_lmtp WHERE username = '%n' AND domain = '%d'
                    password_query = \
                      SELECT username, domain, password \
                      FROM dovecot_passdb_lmtp WHERE username = '%n' AND domain = '%d'
                    iterate_query = SELECT username AS user FROM dovecot_passdb_lmtp
                  '';
                }
              ]
              ++ [
                (genConfig authArgsFilePath) # https://doc.dovecot.org/2.3/configuration_manual/authentication/multiple_authentication_databases/
                {
                  environment.etc.${authArgsFilePath}.text = ''
                    password_query = \
                      SELECT username, domain, password \
                      FROM dovecot_passdb_auth WHERE username = '%n' AND domain = '%d'
                  '';
                }
              ]
            );
        }
      )
    ];
}
