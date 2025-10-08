{
  inputs.base.url = "./base";
  outputs =
    { base, ... }@inputs:
    (base.outputs.withModules inputs {
      nixos = [
        ./configuration.nix
        ./zfs.nix
        ./march.nix
        ./nginx.nix
        ./docker.nix
        "${base.inputs.nixpkgs.outPath}/nixos/modules/profiles/hardened.nix"
      ];
    });
}
