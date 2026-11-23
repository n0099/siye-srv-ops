{
  fetchFromGitHub,
  buildPythonPackage,
  setuptools,
  ta-lib,
  pandas,
}:

buildPythonPackage (finalAttrs: {
  pname = "technical";
  version = "1.7.0";
  src = fetchFromGitHub {
    owner = "freqtrade";
    repo = "technical";
    tag = finalAttrs.version;
    hash = "sha256-Ltab9QTiyH3lSCbHTi+MO2F6joMb1CJjQ6hCznCmP1w=";
  };
  pyproject = true;
  build-system = [ setuptools ];
  dependencies = [
    ta-lib
    pandas
  ];
})
