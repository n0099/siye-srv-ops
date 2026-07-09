{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.freqtrade;
  settingsFormat = pkgs.formats.json { };
in
{
  options.services.freqtrade =
    with {
      inherit (lib) mkOption mkEnableOption;
      inherit (lib.types)
        str
        bool
        port
        submodule
        lazyAttrsOf
        nullOr
        listOf
        externalPath
        ;
    };
    let
      genCommonOptions = cfg: parentCfg: {
        settings = mkOption {
          type = submodule (
            { config, ... }:

            let
              getSetting = key: config.${key} or cfg.settings.${key} or parentCfg.settings.${key};
            in
            {
              freeformType = settingsFormat.type;
              options = {
                dry_run = mkOption {
                  type = bool;
                  default = parentCfg.settings.dry_run or true;
                };
                add_config_files = mkOption {
                  type = listOf externalPath;
                  default = cfg.extraConfigFiles ++ parentCfg.extraConfigFiles or [ ];
                };
                user_data_dir = mkOption {
                  type = externalPath;
                  default =
                    let
                      result = lib.tryEval cfg.userDataDir;
                    in
                    if result.success then result.value else parentCfg.userDataDir;
                };
                db_url =
                  let
                    prefix = if config ? bot_name then "bot-${config.bot_name}" else "tradesv3";
                    infix = lib.optionalString (getSetting "dry_run") ".dryrun";
                  in
                  mkOption {
                    type = str;
                    default = "sqlite://${getSetting "user_data_dir"}/db/${prefix}${infix}.sqlite";
                  };
              };
            }
          );
          default = { };
          apply = value: lib.recursiveUpdate (parentCfg.settings or { }) value;
        };
        extraConfigFiles = mkOption {
          type = listOf externalPath;
          default = [ ];
        };
        userDataDir = mkOption { type = externalPath; };
      };
    in
    {
      enable = mkEnableOption "freqtrade";
      bot = mkOption {
        type =
          ({ name, config, ... }: {
            options = genCommonOptions config cfg;
            config.settings.bot_name = lib.mkDefault name;
          })
          |> submodule
          |> lazyAttrsOf;
      };
      webserver = {
        enable = mkEnableOption "webserver";
        listen = {
          addr = mkOption { type = str; };
          port = mkOption { type = port; };
        };
      }
      // genCommonOptions cfg.webserver cfg;
    }
    // genCommonOptions cfg { };
  config =
    let
      genSystemdService = command: settingsJSON: {
        wantedBy = [ "multi-user.target" ];
        serviceConfig.ExecStart = "${lib.getExe pkgs.freqtrade} ${command} --config ${settingsJSON}";
      };
      commonSystemdService = id: {
        # https://github.com/freqtrade/freqtrade/blob/6fa470939cc74bf0672e0e348a4d9b293072e43c/freqtrade.service.watchdog
        after = [ "network.target" ];
        serviceConfig = {
          # not using `Notify` and passing `--sd-notify` in `ExecStart` to prevent deadlock
          # due to `multi-user.target` of the container waits this unit
          # `ExecStart` of this unit waits for internet access before send `sd_notify()`: https://github.com/freqtrade/freqtrade/blob/158eac5609f13d5fdbd2b09106589a786ae9fcf9/freqtrade/worker.py#L67
          # and `ExecStartPost` of the host unit `container@.service` that setup `ip route` on the host side: https://github.com/NixOS/nixpkgs/blob/667d5cf1c59585031d743c78b394b0a647537c35/nixos/modules/virtualisation/nixos-containers.nix#L297
          # waits `multi-user.target` in the container as `systemd-nspawn` in `ExecStart` waits it: https://github.com/NixOS/nixpkgs/blob/667d5cf1c59585031d743c78b394b0a647537c35/nixos/modules/virtualisation/nixos-containers.nix#L198
          Type = "exec";
          Restart = "on-failure";
          SyslogIdentifier = "freqtrade-${id}";
        };
      };
    in
    {
      services.freqtrade.webserver.settings.api_server = with cfg.webserver.listen; {
        enabled = true;
        listen_ip_address = addr;
        listen_port = port;
      };
      systemd.services = {
        "freqtrade@" = commonSystemdService "bot-%I";
        freqtrade-webserver =
          [
            (
              cfg.webserver.settings
              |> settingsFormat.generate "freqtrade-webserver-settings.json"
              |> genSystemdService "webserver"
            )
            (commonSystemdService "webserver")
          ]
          |> lib.mkMerge
          |> lib.mkIf cfg.webserver.enable;
      }
      // lib.concatMapAttrs (name: botCfg: {
        "freqtrade@${name}" =
          (
            botCfg.settings
            |> settingsFormat.generate "freqtrade-bot-${name}-settings.json"
            |> genSystemdService "trade"
          )
          // {
            overrideStrategy = "asDropin"; # https://github.com/NixOS/nixpkgs/issues/80933#issuecomment-1295396500
          };
      }) cfg.bot;
    }
    |> lib.mkIf cfg.enable;
}
