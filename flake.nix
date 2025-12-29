{
  inputs.base.url = "./base";
  outputs =
    { base, ... }@inputs:

    with { inherit (base.inputs) flake-parts import-tree; };
    flake-parts.lib.mkFlake { inputs = base.inputs // inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        flake-parts.flakeModules.modules
        (import-tree [
          ./base/modules
          ./modules
        ])
      ]
      ++ [
        {
          flake.modules.nixos = {
            secrets.imports = [
              ./base/secrets
              ./secrets
            ];
            configuration.imports = [ ./configuration.nix ];
            # hardened.imports = [ "${base.inputs.nixpkgs.outPath}/nixos/modules/profiles/hardened.nix" ];
          };
        }
      ];
    };

}
