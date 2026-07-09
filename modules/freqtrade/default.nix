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
            global = config.age.secrets."freqtrade.config".path;
            BTCETH = config.age.secrets."freqtrade.BTCETH.config".path;
            alt = config.age.secrets."freqtrade.alt.config".path;
          in
          {
            bindMounts = {
              ${global}.isReadOnly = true;
              ${BTCETH}.isReadOnly = true;
              ${alt}.isReadOnly = true;
            };
            config.services.freqtrade = {
              extraConfigFiles = [ global ];
              bot = {
                BTCETH.extraConfigFiles = [ BTCETH ];
                alt.extraConfigFiles = [ alt ];
              };
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
                bot = {
                  BTCETH = {
                    settings = rec {
                      strategy = "CombinedBinHAndClucVn0099";
                      max_open_trades = exchange.pair_whitelist |> lib.splitString "|" |> lib.length;
                      exchange.pair_whitelist = [
                        # https://www.cryptometer.io/list/binance
                        # https://www.coingecko.com/en/exchanges/binance
                        # https://coinranking.com/exchange/-zdvbieRdZ+binance/markets
                        "(BTC|ETH|SOL|HYPER|XRP|DOGE|AI|TRX|NEAR|PAXG|ENA|WLD|DOGE|TLM|ADA)/USDT"
                      ];
                      pairlists = [
                        { method = "StaticPairList"; }
                        /*
                          {
                            method = "VolumePairList";
                            number_assets = 10;
                            sort_key = "quoteVolume";
                            lookback_days = 30;
                            refresh_period = 86400;
                          }
                        */
                      ];
                      exit_pricing = { };
                      entry_pricing.price_side = "other";
                    };
                    extraConfigFiles = [
                      "${config.services.freqtrade.userDataDir}/strategies/NostalgiaForInfinity/configs/blacklist-binance.json"
                    ];
                  };
                  alt = {
                    settings = {
                      strategy = "NostalgiaForInfinityX7";
                      max_open_trades = 100;
                    };
                    extraConfigFiles =
                      [
                        "trading_mode-spot"
                        "pairlist-volume-binance-usdt"
                        "blacklist-binance"
                        "exampleconfig"
                      ]
                      |> map (
                        filename:
                        "${config.services.freqtrade.userDataDir}/strategies/NostalgiaForInfinity/configs/${filename}.json"
                      );
                  };
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
                  BTCETH = 8081;
                  alt = 8082;
                }
            |> lib.mkMerge;
        }
      ];
    };
}
