{
  fetchFromGitHub,
  buildPythonPackage,
  setuptools,
  wheel,
  requests,
  python-rapidjson,
}:

buildPythonPackage (finalAttrs: {
  pname = "freqtrade-client";
  version = "2026.6";
  src = fetchFromGitHub {
    owner = "freqtrade";
    repo = "freqtrade";
    tag = finalAttrs.version;
    hash = "sha256-C63QcVdvHJTJSJYirIHVFeN5gMo9Hgta/NI5M1diF9U=";
    rootDir = "ft_client";
  };
  pyproject = true;
  build-system = [
    setuptools
    wheel
  ];
  dependencies = [
    requests
    python-rapidjson
  ];
})
