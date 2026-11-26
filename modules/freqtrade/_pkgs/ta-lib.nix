{
  fetchFromGitHub,
  stdenv,
  autoreconfHook,
  buildPythonPackage,
  setuptools,
  cython,
  numpy,
}:

let
  version = "0.8.3";
  ta-lib = stdenv.mkDerivation (finalAttrs: {
    # https://github.com/NixOS/nixpkgs/pull/533696
    pname = "ta-lib";
    inherit version;
    src = fetchFromGitHub {
      owner = "TA-Lib";
      repo = "ta-lib";
      tag = "v${finalAttrs.version}";
      hash = "sha256-mctOWXfnrZT7G6BJhCNVy8KwwsjEkRyohZL0rnvoFIE=";
    };
    nativeBuildInputs = [ autoreconfHook ];
  });
in
buildPythonPackage (finalAttrs: {
  pname = "ta-lib";
  inherit version;
  src = fetchFromGitHub {
    owner = "TA-Lib";
    repo = "ta-lib-python";
    tag = "v${finalAttrs.version}";
    hash = "sha256-zZeI1jMke5T32bwRfRUPZL7r9AgDzOsSnXX+SbmkGzQ=";
  };
  pyproject = true;
  build-system = [
    setuptools
    cython
    numpy
  ];
  dependencies = [ numpy ];
  postPatch = ''
    substituteInPlace pyproject.toml --replace-fail ', "cmake"]' ']'
  '';
  dontConfigure = true; # use already built `ta-lib` to remove `cmake`: https://github.com/TA-Lib/ta-lib-python/blob/b273aa93a97cd027c7b6dc26e50f689400e06667/setup.py#L129
  env = {
    # https://github.com/TA-Lib/ta-lib-python/pull/772
    TA_INCLUDE_PATH = "${ta-lib}/include";
    TA_LIBRARY_PATH = "${ta-lib}/lib";
  };
  buildInputs = [ ta-lib ];
})
