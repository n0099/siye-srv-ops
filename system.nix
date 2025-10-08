{ lib, pkgs, ... }:

lib.mkMerge [
  {
    networking.hostId = "c7635afd";
    boot.zfs.devNodes = "/dev/disk/by-partuuid"; # https://discourse.nixos.org/t/21-05-zfs-root-install-cant-import-pool-on-boot/13652/7
  }
]
