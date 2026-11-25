{
  flake.modules.nixos."containers/freqtrade" =
    { config, lib, ... }:

    {
      containers.freqtrade = lib.mkMerge [
        {
          config.imports = [
            ./_pkgs
            ./_options.nix
          ];
        }
        {
          n0099 = {
            subnetPrefix = "172.16.1.";
            outboundInterface = "ens3";
          };
        }
        (
          let
            getSecretPath = name: config.age.secrets."freqtrade.${name}".path;
            botSecrets = lib.genAttrs [ "future" ] getSecretPath;
            secrets = botSecrets // (lib.genAttrs [ "global" "webserver" ] getSecretPath);
          in
          {
            bindMounts = lib.genAttrs (lib.attrValues secrets) (_: {
              isReadOnly = true;
            });
            config.services.freqtrade = {
              extraConfigFiles = [ secrets.global ];
              webserver.extraConfigFiles = [ secrets.webserver ];
              bot = lib.mapAttrs (_: secret: { extraConfigFiles = [ secret ]; }) botSecrets;
            };
          }
        )
        (
          let
            userDataDir = "/srv/freqtrade";
          in
          {
            bindMounts.${userDataDir} = {
              hostPath = userDataDir;
              isReadOnly = false;
            };
            config.services.freqtrade.userDataDir = userDataDir;
          }
        )
        {
          config =
            { config, pkgs, ... }:

            {
              environment.systemPackages = [ pkgs.freqtrade ];
              services.freqtrade = {
                enable = true;
                settings = {
                  dry_run = false;
                  dry_run_wallet = 100;
                  initial_state = "running";
                  stake_amount = "unlimited";
                  stake_currency = "USDT";
                  exchange.name = "binance";
                };
                webserver.settings = {
                  exchange.pair_whitelist = [ ".*/USDT" ];
                  pairlists = [ { method = "StaticPairList"; } ];
                  recursive_strategy_search = true;
                };
                bot =
                  let
                    mkBot = token: tradingMode: {
                      settings = {
                        strategy = "NostalgiaForInfinityX7";
                        stake_currency = lib.toUpper token;
                        max_open_trades = 100;
                      };
                      extraConfigFiles =
                        [
                          "trading_mode-${tradingMode}"
                          "pairlist-volume-binance-${lib.toLower token}"
                          "blacklist-binance"
                          "exampleconfig"
                        ]
                        |> map (
                          filename:
                          "${config.services.freqtrade.userDataDir}/strategies/NostalgiaForInfinity/configs/${filename}.json"
                        );
                    };
                    mkFuture =
                      token: leverage:
                      lib.mkMerge [
                        (mkBot token "futures")
                        {
                          settings = {
                            nfi_parameters = lib.genAttrs [
                              # https://github.com/iterativv/NostalgiaForInfinity/blob/ded7f037654d308069b59a8dc580b6f30e4cde7e/docs/configuration-guide/configuration-guide.md?plain=1#L54
                              "futures_mode_leverage"
                              "futures_mode_leverage_rebuy_mode"
                              "futures_mode_leverage_grind_mode"
                            ] (_: leverage);
                          }
                          // lib.genAttrs [ "entry_pricing" "exit_pricing" ] (_: {
                            # https://www.freqtrade.io/en/stable/exchanges/#binance-futures
                            use_order_book = true;
                          });
                        }
                      ];
                  in
                  {
                    future = mkFuture "USDT" 4;
                  };
              };
            };
        }
        {
          config =
            let
              addr = "0.0.0.0";
            in
            [
              (
                let
                  port = 8080;
                in
                {
                  networking.firewall.allowedTCPPorts = [ port ];
                  services.freqtrade.webserver = {
                    enable = true;
                    listen = { inherit addr port; };
                  };
                }
              )
            ]
            ++
              lib.mapAttrsToList
                (name: port: {
                  networking.firewall.allowedTCPPorts = [ port ];
                  services.freqtrade.bot.${name}.settings.api_server = {
                    enabled = true;
                    listen_ip_address = addr;
                    listen_port = port;
                  };
                })
                {
                  future = 8082;
                }
            |> lib.mkMerge;
        }
      ];
    };
}
