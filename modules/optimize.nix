{ lib, ... }:

{
  flake.modules.nixos.optimize = {
    n0099.optimize = {
      arch = "znver5";
      stdenv = true;
      python = true;
    };
    nix.gc.automatic = false |> lib.mkForce;
    nixpkgs.overlays = [
      (_: prev: {
        libtpms = prev.libtpms.overrideAttrs (prev: {
          # https://github.com/NixOS/nixpkgs/issues/528643
          configureFlags = (prev.configureFlags or [ ]) ++ [ "CFLAGS=-march=x86-64-v3" ];
        });
      })
    ];
  };
}
