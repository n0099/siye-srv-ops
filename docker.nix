{ lib, pkgs, ... }:

lib.mkMerge [
  {
    users.users.n0099.extraGroups = [ "docker" ];
    virtualisation.docker = {
      enable = true;
      package = pkgs.docker_28;
      autoPrune.enable = true;
      # https://old.reddit.com/r/zfs/comments/17nlapu/docker_on_zfs_best_practices/
      # https://github.com/openzfs/zfs/issues/15581
      # https://blog.chlc.cc/p/docker-and-zfs-a-tough-pair/
      # https://github.com/openzfs/zfs/pull/9600
      storageDriver = "overlay2";
    };
  }
  {
    # https://docs.docker.com/engine/security/userns-remap/
    virtualisation.docker.daemon.settings.userns-remap = "default";
    users = {
      users.dockremap =
        let
          containerUid = 524288; # https://systemd.io/UIDS-GIDS/
        in
        {
          isSystemUser = true;
          subUidRanges = [
            {
              count = 65536;
              startUid = containerUid;
            }
          ];
          subGidRanges = [
            {
              count = 65536;
              startGid = containerUid;
            }
          ];
          group = "dockremap";
        };
      groups.dockremap = { };
    };
  }
]
