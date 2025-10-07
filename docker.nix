{ pkgs, ... }:

{
  # users.users.n0099.extraGroups = [ "docker" ];
  virtualisation.docker = {
    enable = true;
    package = pkgs.docker_28;
    storageDriver = "zfs";
    autoPrune.enable = true;
    daemon.settings.userns-remap = "default";
  };
}
