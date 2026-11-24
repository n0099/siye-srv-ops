{
  callPackage,
  lib,
  pythonOlder,
  fetchFromGitHub,
  buildPythonPackage,
  typing-extensions,
  zlib-ng,
  uvloop,
  coincurve,
  aiosignal,
  attrs,
  frozenlist,
  cffi,
  pycparser,
  charset-normalizer,
}:

let
  pinnedDeps = callPackage ./ccxt-deps.nix { }; # https://github.com/NixOS/nixpkgs/blob/c7e10647eadb53b7cf3552a53e8bb33c8248c8c3/pkgs/by-name/README.md?plain=1#L187-L205
in
buildPythonPackage (finalAttrs: {
  pname = "ccxt";
  version = "4.5.92";
  src = fetchFromGitHub {
    owner = "ccxt";
    repo = "ccxt";
    tag = "v${finalAttrs.version}";
    hash = "sha256-3sL6eIYrhMt7hk0IRRRPforDF7WwyKK6O+EZBp2OjqE=";
  };
  pyproject = true;
  build-system = [ pinnedDeps.setuptools ];
  passthru = { inherit pinnedDeps; };
  dependencies = [
    pinnedDeps.setuptools
    pinnedDeps.certifi
    pinnedDeps.requests
    pinnedDeps.cryptography
    typing-extensions
    pinnedDeps.aiohttp
    pinnedDeps.yarl
    pinnedDeps.aiohttp-fast-zlib
    zlib-ng
    uvloop
  ]
  # https://github.com/ccxt/ccxt/blob/e6fd82900c9f2b71fa0fa7524d95dd788e2803fc/pyproject.toml#L68
  ++ lib.optional (pythonOlder "3.15") pinnedDeps.orjson
  ++ lib.optional (pythonOlder "3.14") coincurve
  ++ [
    pinnedDeps.aiohappyeyeballs
    aiosignal
    attrs
    frozenlist
    pinnedDeps.multidict
    pinnedDeps.propcache
    cffi
    pycparser
    charset-normalizer
    pinnedDeps.idna
    pinnedDeps.urllib3
  ];
})
