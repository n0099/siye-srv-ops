{ config, lib, ... }:

let
  proxyPassPortsByUrl = {
    "z.n0099.net" = [ { "/" = 9002; } ];
    "simcity.moe" = [ { "/" = 9003; } ];
    "mcbar.club" = [ { "/" = 9004; } ];
    "n0099.net" = [
      { "/v" = 9005; }
      { "/tc" = 9006; }
      { "/pma" = 9007; }
      { "/tbm/v1" = 9008; }
      { "/tbm/be" = 9009; }
      { "/tbm" = 3001; }
    ];
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
  n0099.nginx.baseUrls = lib.flatten (
    lib.mapAttrsToList (
      domain: baseUrlsKeyByPort:
      lib.concatMap (
        baseUrlKeyByPort: lib.map (baseUrl: "${domain}${baseUrl}") (lib.attrNames baseUrlKeyByPort)
      ) baseUrlsKeyByPort
    ) proxyPassPortsByUrl
  );
  services.nginx = {
    virtualHosts = lib.mkMerge [
      (lib.genAttrs [
        "mcbar.club"
        "simcity.moe"
        "n0099.net"
      ] (domain: certByDomain domain))
      (lib.mapAttrs (_: baseUrlsKeyByPort: {
        locations = lib.mkMerge (
          lib.map (lib.mapAttrs (
            _: port: { proxyPass = "http://127.0.0.1:${builtins.toString port}"; }
          )) baseUrlsKeyByPort
        );
      }) proxyPassPortsByUrl)
      {
        "z.n0099.net" = (certByDomain "n0099.net") // {
          locations = {
            "/".extraConfig = ''
              # https://zulip.readthedocs.io/en/9.4/production/reverse-proxies.html#nginx-configuration
              proxy_buffering off;
            '';
            "/error/".root = "/srv/www/n0099";
          };
          extraConfig = ''
            error_page 502 /error/502_zulip.html;
          '';
        };
      }
    ];
  };
}
