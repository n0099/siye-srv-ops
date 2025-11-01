{
  config,
  lib,
  pkgs,
  ...
}:

let
  proxyPassByUrl = {
    "z.n0099.net" = [ { "/" = "localhost:9002"; } ];
    "simcity.moe" = [ { "/" = "localhost:9003"; } ];
    "mcbar.club" = [ { "/" = "localhost:9004"; } ];
    "n0099.net" = [
      { "/v" = "localhost:9005"; }
      { "/tc" = "localhost:9006"; }
      { "/pma" = "localhost:9007"; }
      { "/tbm/v1" = "localhost:9008"; }
      { "/tbm/be" = "localhost:9009"; }
      { "/tbm" = "localhost:3001"; }
      { "/rc" = config.containers.email.localAddress; }
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
      domain: urlPathsKeyByProxyPass:
      lib.concatMap (
        urlPathKeyByProxyPass:
        let
          concatBaseUrl = path: "${domain}${lib.optionalString (path != "/") path}";
        in
        (lib.map concatBaseUrl (lib.attrNames urlPathKeyByProxyPass))
      ) urlPathsKeyByProxyPass
    ) proxyPassByUrl
  );
  services.nginx = lib.mkMerge [
    {
      virtualHosts = lib.mkMerge [
        (lib.genAttrs [
          "mcbar.club"
          "simcity.moe"
          "n0099.net"
        ] (domain: certByDomain domain))
        (lib.mapAttrs (_: baseUrlsKeyByProxyPass: {
          locations = lib.mkMerge (
            lib.map (lib.mapAttrs (_: proxyPass: { proxyPass = "http://${proxyPass}"; })) baseUrlsKeyByProxyPass
          );
        }) proxyPassByUrl)
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
              locations =
                (lib.genAttrs (lib.map (url: "/${url}") [
                  "error"
                  "favicon.ico"
                  "robots.txt"
                  "BingSiteAuth.xml"
                ]) (_: { }))
                // {
                  "= /".tryFiles = "/index.html =404";
                  "/".return = "302 https://n0099.net";
                };
            }
            {
              locations = lib.mkMerge [
                {
                  "~ '/tbm/imgsrc/([0-9a-f]{40}|[0-9a-f]{24})'" = {
                    # https://github.com/lumina37/aiotieba/pull/63#issuecomment-2447263162
                    proxyPass = "https://imgsrc.baidu.com/forum/pic/item/$1.jpg";
                    recommendedProxySettings = false;
                    extraConfig = ''
                      proxy_set_header Referer https://tieba.baidu.com/;
                      valid_referers server_names localhost; # none for https://github.com/n0099/open-tbm/blob/609a21bfed11b291aaa860c589aa2acf2590ce24/fe/src/components/OgImage/Post.vue#L22
                      if ($invalid_referer) {
                          return 403;
                      }
                    '';
                  };
                  "~ ^/tbm/tbm/([^\\r\\n]*)".return = "301 /tbm/$1"; # temp fix for google seo due to https://github.com/harlan-zw/nuxt-site-config/issues/32
                  "/posts/".return = "301 /tbm$request_uri"; # temp fix for google trying to crawl https://n0099.net/posts/*
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
    }
    {
      additionalModules = [ pkgs.nginxModules.moreheaders ];
      virtualHosts."n0099.net".locations = {
        "/live2d/" = {
          index = "index.js";
          extraConfig = ''
            more_set_headers "Access-Control-Allow-Origin: https://z.n0099.net";
          '';
        };
        "~ ^/live2d/.+/".extraConfig = ''
          more_set_headers "Cache-Control: public, max-age=31536000, immutable";
        '';
      };
    }
  ];
}
