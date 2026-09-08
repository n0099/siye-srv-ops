{ lib, ... }:

{
  flake.modules.nixos.optimize = {
    n0099.optimize = {
      arch = "znver5";
      stdenv = true;
      python = true;
    };
    nix.gc.automatic = false |> lib.mkForce;
  };
}
