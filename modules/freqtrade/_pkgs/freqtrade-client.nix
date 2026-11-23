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
  version = "2026.10";
  src = fetchFromGitHub {
    owner = "freqtrade";
    repo = "freqtrade";
    tag = finalAttrs.version;
    hash = "sha256-L/iZC4kKsQjgKw3X3uK7ZeMsjsS/Y9miJfj5dy1jfWA=";
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
