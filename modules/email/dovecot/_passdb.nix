config:

let
  dbConnect = config.age.secrets."dovecot.db.connect".path;
  genArgsFilePath = type: "dovecot/dovecot-passdb-sql-${type}.conf.ext";
  genDovecotPassDB = argsFilePath: {
    services.dovecot2.settings.passdb = [
      {
        driver = "sql";
        args = "/etc/${argsFilePath}";
      }
    ];
    environment.etc.${argsFilePath}.text = ''
      !include ${dbConnect}
      driver = mysql
      default_pass_scheme = ARGON2ID # https://doc.dovecot.org/2.3/configuration_manual/authentication/sql/#password-database-lookups
    '';
  };
in
{
  inherit dbConnect genArgsFilePath genDovecotPassDB;
  containerConfig.bindMounts.${dbConnect}.isReadOnly = true;
}
