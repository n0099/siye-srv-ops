{
  flake.modules.nixos.nginx =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    {
      services.nginx = lib.mkMerge [
        {
          n0099.proxyPassByUrl = {
            "z.n0099.net" = [ { "/" = "127.0.0.1:9002"; } ];
            "simcity.moe" = [ { "/" = "127.0.0.1:9003"; } ];
            "mcbar.club" = [ { "/" = "127.0.0.1:9004"; } ];
            "n0099.net" = [
              { "/v" = "127.0.0.1:9005"; }
              { "/tc" = "127.0.0.1:9006"; }
              { "/pma" = "127.0.0.1:9007"; }
              { "/tbm/v1" = "127.0.0.1:9008"; }
              { "/tbm/be" = "127.0.0.1:9009"; }
              { "/tbm" = "127.0.0.1:3001"; }
              { "/rc" = config.containers.email.localAddress; }
            ];
          };
        }
        {
          virtualHosts = lib.mkMerge [
            {
              "z.n0099.net" = {
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
                    (lib.genAttrs (map (url: "/${url}") [
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
          virtualHosts."n0099.net".locations = lib.mkMerge [
            {
              "/live2d/" = {
                index = "index.js";
                extraConfig = ''
                  more_set_headers "Access-Control-Allow-Origin: https://z.n0099.net";
                '';
              };
              "~ ^/live2d/.+/".extraConfig = ''
                more_set_headers "Cache-Control: public, max-age=31536000, immutable";
              '';
            }
            {
              "/rc".extraConfig = ''
                more_set_headers "X-Frame-Options: SAMEORIGIN"; # https://github.com/roundcube/roundcubemail/issues/6882
              '';
            }
          ];
        }
      ];
    };
}
