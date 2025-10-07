{
  inputs.base.url = "./base";
  outputs =
    { base, ... }@inputs:
    (base.outputs.withModules inputs {
      nixos = [
        ./configuration.nix
      ];
    });
}
