{
  fetchFromGitHub,
  stdenv,
  autoreconfHook,
  buildPythonPackage,
  setuptools,
  wheel,
  cython,
  numpy,
  build,
}:

buildPythonPackage (finalAttrs: {
  pname = "ta-lib";
  version = "0.6.8";
  src = fetchFromGitHub {
    owner = "TA-Lib";
    repo = "ta-lib-python";
    tag = "v${finalAttrs.version}";
    hash = "sha256-fgi/TkXb6UdjA8YohraW1Xn7aOLbNdt01SfCzyU0a2Y=";
  };
  pyproject = true;
  build-system = [
    setuptools
    wheel
    cython
    numpy
  ];
  dependencies = [
    build
    numpy
  ];
  buildInputs = [
    (stdenv.mkDerivation (finalAttrs: {
      # https://github.com/NixOS/nixpkgs/pull/533696
      pname = "ta-lib";
      version = "0.6.4";
      src = fetchFromGitHub {
        owner = "TA-Lib";
        repo = "ta-lib";
        tag = "v${finalAttrs.version}";
        hash = "sha256-aTRiScPNWsGDwJvumZXlMilvSDYZVDWgpeZ2F/S5WgQ=";
      };
      nativeBuildInputs = [ autoreconfHook ];
    }))
  ];
})
