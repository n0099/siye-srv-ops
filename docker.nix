{ lib, pkgs, ... }:

lib.mkMerge [
  {
    users.users.n0099.extraGroups = [ "docker" ];
    virtualisation.docker = {
      enable = true;
      package = pkgs.docker_28;
      storageDriver = "zfs";
      autoPrune.enable = true;
    };
  }
  {
    # https://docs.docker.com/engine/security/userns-remap/
    virtualisation.docker.daemon.settings.userns-remap = "default";
    users = {
      users.dockremap = {
        isSystemUser = true;
        subUidRanges = [
          # https://systemd.io/UIDS-GIDS/
          {
            count = 65536;
            startUid = 524288;
          }
        ];
        subGidRanges = [
          {
            count = 65536;
            startGid = 524288;
          }
        ];
        group = "dockremap";
      };
      groups.dockremap = { };
    };
  }
]
