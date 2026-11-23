{
  lib,
  pythonOlder,
  fetchFromGitHub,
  buildPythonPackage,
  setuptools,
  certifi,
  requests,
  cryptography,
  typing-extensions,
  aiohttp,
  yarl,
  aiohttp-fast-zlib,
  zlib-ng,
  uvloop,
  orjson,
  coincurve,
  aiohappyeyeballs,
  aiosignal,
  attrs,
  frozenlist,
  multidict,
  propcache,
  cffi,
  pycparser,
  charset-normalizer,
  idna,
  urllib3,
}:

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
  build-system = [ setuptools ];
  passthru = { inherit pinnedDeps; };
  dependencies = [
    setuptools
    certifi
    requests
    cryptography
    typing-extensions
    aiohttp
    yarl
    aiohttp-fast-zlib
    zlib-ng
    uvloop
  ]
  # https://github.com/ccxt/ccxt/blob/e6fd82900c9f2b71fa0fa7524d95dd788e2803fc/pyproject.toml#L68
  ++ lib.optional (pythonOlder "3.15") orjson
  ++ lib.optional (pythonOlder "3.14") coincurve
  ++ [
    aiohappyeyeballs
    aiosignal
    attrs
    frozenlist
    multidict
    propcache
    cffi
    pycparser
    charset-normalizer
    idna
    urllib3
  ];
})
