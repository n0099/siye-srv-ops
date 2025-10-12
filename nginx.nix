{ lib, ... }:

let
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
  services.nginx = {
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
