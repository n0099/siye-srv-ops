{
  fetchFromGitHub,
  buildPythonPackage,
  poetry-core,
}:

buildPythonPackage (finalAttrs: {
  pname = "ast-comments";
  version = "1.3.0";
  src = fetchFromGitHub {
    owner = "t3rn0";
    repo = "ast-comments";
    tag = finalAttrs.version;
    hash = "sha256-Ji0nFjoNAtLQk7334GYZpe+TNn6+M9h1meJeI5v82M0=";
  };
  pyproject = true;
  build-system = [ poetry-core ];
})
