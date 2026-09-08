{
  flake.modules.nixos."containers/email/mysql" =
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
      containers.email = lib.mkMerge (
        (
          let
            mysqlSocket = "/run/mysqld/mysqld.sock";
          in
          [
            { bindMounts.${mysqlSocket}.isReadOnly = true; }
            (
              let
                hostPrivateKey = "/etc/ssh/ssh_host_ed25519_key";
                secretName = "roundcube.db.password";
              in
              {
                bindMounts.${hostPrivateKey}.isReadOnly = true;
                config =
                  { config, ... }:

                  {
                    # https://wiki.nixos.org/wiki/Agenix#Access_secrets_inside_a_container
                    imports = [ inputs.agenix.nixosModules.default ];
                    age = {
                      identityPaths = [ hostPrivateKey ];
                      secrets.${secretName} = {
                        file = ../../secrets/${secretName}.age;
                        symlink = false;
                        owner = "nginx";
                      };
                    };
                    services.roundcube = {
                      database = {
                        host = "unix(${mysqlSocket})";
                        passwordFile = config.age.secrets.${secretName}.path;
                        dbname = "email";
                        username = "email";
                      };
                      extraConfig = /* php_only */ ''
                        $config['db_dsnw'] = preg_replace('#^pgsql://#', 'mysql://', $config['db_dsnw']);
                        $config['db_prefix'] = 'roundcube_';
                      '';
                    };
                  };
              }
            )
          ]
        )
        ++ (
          with {
            inherit (import ./dovecot/_passdb.nix config)
              dbConnect
              genArgsFilePath
              genDovecotPassDB
              containerConfig
              ;
          };
          let
            lmtpArgsFilePath = genArgsFilePath "lmtp";
          in
          [
            containerConfig
            {
              config =
                { pkgs, ... }:

                lib.mkMerge [
                  (genDovecotPassDB lmtpArgsFilePath)
                  {
                    services.dovecot2.package = pkgs.dovecot_2_3.override {
                      # https://github.com/NixOS/nixpkgs/blob/6b316287bae2ee04c9b93c8c858d930fd07d7338/pkgs/by-name/do/dovecot/generic.nix#L48-L52
                      withMySQL = true;
                      withSQLite = false;
                    };
                  }
                  {
                    services.dovecot2.settings.userdb = {
                      driver = "sql";
                      args = "/etc/${lmtpArgsFilePath}";
                    };
                    environment.etc.${lmtpArgsFilePath}.text = /* sql */ ''
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
                ];
            }
          ]
        )
      );
    };
}
