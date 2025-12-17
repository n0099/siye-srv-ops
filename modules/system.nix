{
  flake.modules.nixos.system =
    { lib, pkgs, ... }:

    lib.mkMerge [
      {
        boot.kernelPackages =
          {
            argsOverride = rec {
              # wait for zfs 2.4 to support kernel up to 6.17
              # https://wiki.nixos.org/wiki/Linux_kernel#Pinning_a_kernel_version
              # https://cdn.kernel.org/pub/linux/kernel/v6.x/
              version = "6.16.12";
              modDirVersion = version;
              src = pkgs.fetchurl {
                url = "mirror://kernel/linux/kernel/v${lib.versions.major version}.x/linux-${version}.tar.xz";
                hash = "sha256-fKTevFypEuu4p2lEpcEYr9XQnjHvQ8SUrbFCc9opom4=";
              };
            };
          }
          |> pkgs.linuxKernel.kernels.linux_latest.override
          |> pkgs.linuxPackagesFor;
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
