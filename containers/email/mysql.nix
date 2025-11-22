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
    [
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
        with {
          inherit (import ./dovecot-passdb.nix config)
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
            config = lib.mkMerge [
              (genDovecotPassDB lmtpArgsFilePath)
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
            ];
          }
        ]
      )
    ]
    |> lib.flatten
    |> lib.mkMerge;
}
