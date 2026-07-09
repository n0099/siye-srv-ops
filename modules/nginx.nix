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
          }
          // (
            let
              host = config.containers.freqtrade.localAddress;
            in
            {
              "ft-ws.n0099.com" = [ { "/" = "${host}:8080"; } ];
              "ft1.n0099.com" = [ { "/" = "${host}:8081"; } ];
              "ft2.n0099.com" = [ { "/" = "${host}:8082"; } ];
            }
          );
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
                root = "/srv/www/n0099.com";
              }
              // genEmptyLocation [ "/error/" ];
              genEmptyLocation = locations: {
                # to allow urls bypass the `location / {}` block
                locations = lib.genAttrs locations (_: { });
              };
              permanentRedirectTo = target: {
                # https://stackoverflow.com/questions/42136829/whats-the-difference-between-http-301-and-308-status-codes
                return = "308 ${target}";
                extraConfig = ''
                  # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/http-3xx-status-codes.html
                  add_header Cache-Control max-age=${daysToSeconds 7};
                '';
              };
              daysToSeconds = days: days * 24 * 60 * 60 |> toString;
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
                  {
                    locations = {
                      "/" = permanentRedirectTo "https://n0099.com$request_uri";
                    }
                    // {
                      "= /mc".return = "302 $request_uri/";
                      "/mc/".return = "302 https://mc.n0099.net:44444";
                      "= /mc/3d".return = "302 $request_uri/";
                      "/mc/3d/".return = "302 https://mc.n0099.net:44444/3d/";
                    };
                  }
                ];
              }
              {
                "n0099.com" = lib.mkMerge (
                  [ httpErrorPages ]
                  ++ [
                    (genEmptyLocation [ "= /" ])
                    { locations."/".tryFiles = "$uri $uri/ =404"; }
                  ]
                  ++ [
                    {
                      locations = {
                        "/tbm/v1/".extraConfig = ''
                          add_header Cache-Control 'max-age=${daysToSeconds 365}, immutable';
                        '';
                        "~ '/tbm/imgsrc/([0-9a-f]{40}|[0-9a-f]{24})'" = {
                          # https://github.com/lumina37/aiotieba/pull/63#issuecomment-2447263162
                          proxyPass = "https://imgsrc.baidu.com/forum/pic/item/$1.jpg";
                          recommendedProxySettings = false;
                          extraConfig = ''
                            proxy_set_header Referer https://tieba.baidu.com/;
                          '';
                        };
                        "~ ^/tbm/tbm/([^\\r\\n]*)" = permanentRedirectTo "/tbm/$1"; # temp fix for google seo due to https://github.com/harlan-zw/nuxt-site-config/issues/32
                        "/posts/" = permanentRedirectTo "/tbm$request_uri"; # temp fix for google trying to crawl https://n0099.net/posts/*
                      };
                    }
                  ]
                );
              }
              (lib.genAttrs [ "ft-ws.n0099.com" "ft1.n0099.com" "ft2.n0099.com" ] (_: {
                locations."/".proxyWebsockets = true; # https://www.freqtrade.io/en/stable/rest-api/#message-websocket
              }))
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
