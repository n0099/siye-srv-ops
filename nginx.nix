{ config, lib, ... }:

{
  services.nginx.virtualHosts = {
    "z.n0099.net" = {
      inherit (config.services.nginx.virtualHosts.default) forceSSL sslCertificate sslCertificateKey;
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
      extraConfig = ''
        error_page 502 /error/502_zulip.html;
      '';
    };
  };
}
