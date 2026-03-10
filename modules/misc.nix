{
  flake.modules.nixos.misc =
    { lib, pkgs, ... }:

    lib.mkMerge [
      {
        n0099.cachyos = {
          enable = true;
          variant = "server-lto";
        };
      }
      {
        networking.hostId = "c7635afd";
        boot.zfs = {
          package = pkgs.zfs_2_4;
          devNodes = "/dev/disk/by-partuuid"; # https://discourse.nixos.org/t/21-05-zfs-root-install-cant-import-pool-on-boot/13652/7
        };
      }
      {
        n0099.stdenv.enable = true;
      }
    ];
}
