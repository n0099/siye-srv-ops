{ lib, ... }:

{
  flake.modules.nixos.march = {
    n0099.march = {
      enable = true;
      arch = "znver5";
    };
    nix.gc.automatic = false |> lib.mkForce;
  };
}
