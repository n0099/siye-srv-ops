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
  version = "2026.5.1";
  src = fetchFromGitHub {
    owner = "freqtrade";
    repo = "freqtrade";
    tag = finalAttrs.version;
    hash = "sha256-OutN8RGRBnMwgs/ZFEi6wNyJafLHtXSb3gDcURk1FmE=";
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
