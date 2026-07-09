{
  lib,
  pythonAtLeast,
  pythonOlder,
  fetchFromGitHub,
  buildPythonPackage,
  setuptools,
  certifi,
  requests,
  cryptography,
  typing-extensions,
  aiohttp,
  aiodns,
  yarl,
  coincurve,
}:

buildPythonPackage (finalAttrs: {
  pname = "ccxt";
  version = "4.5.59";
  src = fetchFromGitHub {
    owner = "ccxt";
    repo = "ccxt";
    tag = "v${finalAttrs.version}";
    hash = "sha256-YudOCr2EhFnHRacyeBzsjACxIGcNXwoHuCvw7M7oL0w=";
  };
  pyproject = true;
  build-system = [ setuptools ];
  dependencies = [
    setuptools
    certifi
    requests
    cryptography
    typing-extensions
  ]
  # https://github.com/ccxt/ccxt/blob/6712b7500c6dd888978047466d6ad9b49604d73b/python/setup.py#L89
  ++ lib.optionals (pythonAtLeast "3.5.2") [
    aiohttp
    aiodns
    yarl
  ]
  ++ lib.optional (pythonAtLeast "3.9" && pythonOlder "3.14") coincurve;
})
