{ lib, pkgs, ... }:

{
  services = {
    mysql = {
      enable = true;
      package = pkgs.mysql80;
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql;
      settings.listen_addresses = lib.mkForce "localhost, 172.17.0.1";
      authentication = ''
        host all all 172.16.0.0/12 scram-sha-256
      '';
    };
  };
}
