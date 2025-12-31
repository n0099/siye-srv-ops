{
  flake.modules.nixos.misc =
    { lib, pkgs, ... }:

    lib.mkMerge [
      {
        boot.zfs.package = pkgs.zfs_2_4;
        boot.kernelPackages = pkgs.linuxPackages_6_18;
      }
      {
        networking.hostId = "c7635afd";
        boot.zfs.devNodes = "/dev/disk/by-partuuid"; # https://discourse.nixos.org/t/21-05-zfs-root-install-cant-import-pool-on-boot/13652/7
      }
      {
        services.qemuGuest.enable = true;
      }
    ];
}
