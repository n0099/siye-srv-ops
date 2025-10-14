{ lib, pkgs, ... }:

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
      {
        "n0099.net" = lib.mkMerge [
          {
            locations."/error" = { };
            extraConfig = ''
              error_page 401 /error/401.html;
              error_page 403 /error/403.html;
              error_page 404 /error/404.html;
              error_page 500 /error/500.html;
              error_page 502 /error/502.html;
            '';
          }
          {
            root = "/srv/www/n0099";
            locations = lib.genAttrs [ "favicon.ico" "robots.txt" "BingSiteAuth.xml" ] (_: { });
          }
          {
            locations = lib.mkMerge [
              {
                "= /".tryFiles = "/index.html =404";
                "/".return = "302 https://n0099.net";
              }
              {
                "~ '/tbm/imgsrc/([0-9a-f]{40}|[0-9a-f]{24})'" = {
                  # https://github.com/lumina37/aiotieba/pull/63#issuecomment-2447263162
                  proxyPass = "https://imgsrc.baidu.com/forum/pic/item/$1.jpg;";
                  extraConfig = ''
                    proxy_set_header  Referer https://tieba.baidu.com/;
                    valid_referers    none server_names localhost; # none for https://github.com/n0099/open-tbm/blob/609a21bfed11b291aaa860c589aa2acf2590ce24/fe/src/components/OgImage/Post.vue https://github.com/nuxt-modules/og-image/issues/190
                    if ($invalid_referer) {
                        return 403;
                    }
                  '';
                };
                "~ ^/tbm/tbm/(.*)".return = "301 /tbm/$1"; # temp fix for google seo due to https://github.com/harlan-zw/nuxt-site-config/issues/32
                "/posts".return = "301 /tbm$uri"; # temp fix for google trying to crawl https://n0099.net/posts/*
              }
              {
                "/mc/".return = "302 https://mc.n0099.net:44444";
                "/mc/3d/".return = "302 https://mc.n0099.net:44444/3d/";
              }
            ];
          }
        ];
      }
    ];
  };
}
