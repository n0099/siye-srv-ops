{ lib, ... }:

let
  proxyPassPortsKeyByUri = {
    "simcity.moe" = 9003;
    "mcbar.club" = 9004;
    "n0099.net/v" = 9005;
    "n0099.net/tc" = 9006;
    "n0099.net/pma" = 9007;
    "n0099.net/tbm/v1" = 9008;
    "n0099.net/tbm/be" = 9009;
    "n0099.net/tbm" = 3001;
  };
  certByDomain =
    domain:
    let
      certBasePath = "/etc/ssl/certs/${domain}";
    in
    {
      forceSSL = true;
      sslCertificate = "${certBasePath}/fullchain.pem"; # https://stackoverflow.com/questions/26191463/ssl-error0b080074x509-certificate-routinesx509-check-private-keykey-values/41154564#41154564
      sslCertificateKey = "${certBasePath}/privkey.pem";
    };
in
{
  n0099.nginx.baseUrls = lib.attrNames proxyPassPortsKeyByUri;
  services.nginx = {
    appendHttpConfig = ''
      map $host$uri $proxy_pass_port {
        ${lib.concatMapAttrsStringSep "\n" (
          uri: port: "~^${lib.escapeRegex uri}/ ${builtins.toString port};"
        ) proxyPassPortsKeyByUri}
      }
    '';
    virtualHosts = {
      "z.n0099.net" = (certByDomain "n0099.net") // {
        locations = {
          "/" = {
            proxyPass = (import ./base/toBeFilled/lib.nix lib).readString ./toBeFilled/nginx/zulip/proxyPass;
            extraConfig = ''
              # https://zulip.readthedocs.io/en/9.4/production/reverse-proxies.html#nginx-configuration
              proxy_buffering off;
            '';
          };
          "/error/".root = "/srv/www/n0099";
        };
      };
      extraConfig = ''
        error_page 502 /error/502_zulip.html;
      '';
    };
  };
}
