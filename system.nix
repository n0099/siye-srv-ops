{ lib, pkgs, ... }:

lib.mkMerge [
  {
    boot.kernelPackages = pkgs.linuxPackages_6_16;
  }
  {
    networking.hostId = "c7635afd";
    boot.zfs.devNodes = "/dev/disk/by-partuuid"; # https://discourse.nixos.org/t/21-05-zfs-root-install-cant-import-pool-on-boot/13652/7
  }
  {
    services.qemuGuest.enable = true;
  }
  {
    services = {
      mysql = {
        enable = true;
        package = pkgs.mysql80;
      };
      postgresql = {
        enable = true;
        package = pkgs.postgresql;
      };
    };
  }
]
