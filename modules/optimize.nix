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
      (
        _: prev:
        let # https://github.com/NixOS/nixpkgs/issues/548402
          override =
            pkg:
            prev.${pkg}.overrideAttrs (prev: {
              checkFlags = lib.map (
                flag:
                if lib.hasPrefix "CI_SKIP_TESTS=" flag then
                  "${flag},"
                  + lib.concatStringsSep "," [
                    "test-tls-over-http-tunnel"
                    "test-http-agent-keepalive"
                    "test-https-proxy-request-invalid-char-in-url"
                  ]
                else
                  flag
              ) (prev.checkFlags or [ ]);
            });
        in
        {
          nodejs-slim = override "nodejs-slim";
          nodejs_24 = prev.nodejs_24.override {
            nodejs-slim = override "nodejs-slim";
          };
        }
      )
    ];
  };
}
