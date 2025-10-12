{
  inputs.base.url = "./base";
  outputs =
    { base, ... }@inputs:
    (base.outputs.withModules inputs {
      nixos = [
        ./configuration.nix
        ./system.nix
        ./march.nix
        ./nginx.nix
        ./docker.nix
        ./ipv6.nix
        "${base.inputs.nixpkgs.outPath}/nixos/modules/profiles/hardened.nix"
      ];
      home-manager = [ ./home/n0099.nix ];
    });
}
