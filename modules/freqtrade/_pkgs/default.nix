{
  nixpkgs.overlays = [
    (_: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (_: prev: {
          # https://github.com/NixOS/nixpkgs/issues/533557
          scipy = prev.scipy.overridePythonAttrs { doCheck = false; };
        })
      ];
      rapidjson = prev.rapidjson.overrideAttrs { doCheck = false; }; # https://github.com/NixOS/nixpkgs/issues/451374
    })
    (final: prev: {
      freqtrade = final.python3Packages.callPackage ./freqtrade.nix { };
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (final: _: {
          ccxt = final.callPackage ./ccxt.nix { };
          ta-lib = final.callPackage ./ta-lib.nix { };
          ft-pandas-ta = final.callPackage ./ft-pandas-ta.nix { };
          technical = final.callPackage ./technical.nix { };
          pycoingecko = final.callPackage ./pycoingecko.nix { };
          ast-comments = final.callPackage ./ast-comments.nix { };
        })
      ];
    })
  ];
}
