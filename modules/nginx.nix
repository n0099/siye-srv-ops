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
            "n0099.net" = [ { "/v" = "127.0.0.1:9005"; } ];
            "n0099.com" = [
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
          virtualHosts =
            let
              httpErrorPages = {
                extraConfig = lib.concatStringsSep "\n" (
                  [
                    # https://github.com/n0099/httpErrorPage
                    401
                    403
                    404
                    500
                    502
                  ]
                  |> map toString
                  |> map (statusCode: "error_page ${statusCode} /error/${statusCode}.html;")
                );
                root = "/srv/www/n0099";
              }
              // genEmptyLocation [ "error" ];
              genEmptyLocation = locations: {
                # to allow urls bypass the `location / {}` block
                locations = (lib.genAttrs (map (url: "/${url}") locations) (_: { }));
              };
            in
            lib.mkMerge [
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
                  httpErrorPages
                  (genEmptyLocation [ "BingSiteAuth.xml" ])
                  {
                    locations = {
                      "/".return = "301 https://n0099.com$request_uri";
                    }
                    // {
                      "/mc/".return = "302 https://mc.n0099.net:44444";
                      "/mc/3d/".return = "302 https://mc.n0099.net:44444/3d/";
                    };
                  }
                ];
              }
              {
                "n0099.com" = lib.mkMerge [
                  httpErrorPages
                  (genEmptyLocation [
                    "favicon.ico"
                    "robots.txt"
                  ])
                  {
                    locations = lib.mkMerge [
                      {
                        "= /".tryFiles = "/index.html =404";
                        "/".return = "302 https://n0099.com";
                      }
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
                    ];
                  }
                ];
              }
            ];
        }
        {
          additionalModules = [ pkgs.nginxModules.moreheaders ];
          virtualHosts."n0099.com".locations = lib.mkMerge [
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
              "/rc/".extraConfig = ''
                more_set_headers "X-Frame-Options: SAMEORIGIN"; # https://github.com/roundcube/roundcubemail/issues/6882
              '';
            }
          ];
        }
      ];
    };
}
