config:

let
  dbConnect = config.age.secrets."dovecot.db.connect".path;
  genArgsFilePath = type: "dovecot/dovecot-passdb-sql-${type}.conf.ext";
  genDovecotPassDB = argsFilePath: {
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
{
  inherit dbConnect genArgsFilePath genDovecotPassDB;
  containerConfig = {
    bindMounts."${dbConnect}".isReadOnly = true;
    config = {
      nixpkgs.overlays = [
        (self: super: {
          # https://github.com/NixOS/nixpkgs/blob/78e34d1667d32d8a0ffc3eba4591ff256e80576e/pkgs/by-name/do/dovecot/package.nix#L37
          # https://github.com/NixOS/nixpkgs/pull/14898
          dovecot = super.dovecot.override { withMySQL = true; };
        })
      ];
    };
  };
}
