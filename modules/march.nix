{ lib, ... }:

{
  flake.modules.nixos.march = {
    n0099.march = {
      enable = true;
      arch = "znver5";
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
