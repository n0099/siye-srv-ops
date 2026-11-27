{
  fetchFromGitHub,
  rustPlatform,
  setuptools,
  certifi,
  cryptography,
  aiohttp,
  aiodns,
  pycares,
  pytest-timeout,
  orjson,
  aiohappyeyeballs,
  multidict,
  coverage,
  propcache,
  idna,
  urllib3,
  aiohttp-fast-zlib,
  yarl,
  requests,
}:

# https://github.com/ccxt/ccxt/pull/29093
# TODO: re-check versions when upgrade to a new NixOS branch
# diff `python3*Packages.*` in the nixpkgs repo:
# $ git diff $remote/nixos-{$current_branch,unstable} -- pkgs/development/python-modules/$package/default.nix
let
  certifi' = certifi.overridePythonAttrs rec {
    # https://github.com/NixOS/nixpkgs/pull/554025/changes/f64b15a4f03d3c7715f713934fd91d3d776daa75
    version = "2026.07.22";
    src = fetchFromGitHub {
      owner = "certifi";
      repo = "python-certifi";
      tag = version;
      hash = "sha256-euVWKJiFsx7F8YRMgRrrHswBmDBmrV/guiuvqtSUnSs=";
    };
  };
  cryptography' = cryptography.overrideAttrs (
    final: _: {
      # https://github.com/NixOS/nixpkgs/pull/569604
      version = "50.0.2";
      src = fetchFromGitHub {
        owner = "pyca";
        repo = "cryptography";
        tag = final.version;
        hash = "sha256-FbJ3dCur3P7tf6Y617KuX0Gp9ptIlxIlZ7C9GYCoCe0=";
      };
      cargoDeps = rustPlatform.fetchCargoVendor {
        inherit (final) pname version src;
        hash = "sha256-OUfcs3MIoEwUx1BQV1ZYnAx9IDEbQUWEaeddwK0LLmQ=";
      };
      # https://github.com/NixOS/nixpkgs/pull/549356
      # https://github.com/NixOS/nixpkgs/pull/569137/changes/b40d316f4d9d927f31f0e5ffe8bece7858490255
      patches = [ ];
    }
  );
  aiohttp' =
    (aiohttp.override {
      aiohappyeyeballs = aiohappyeyeballs';
      multidict = multidict';
      propcache = propcache';
      yarl = yarl';
      aiodns = aiodns.override { pycares = pycares.override { idna = idna'; }; };
    }).overridePythonAttrs
      (
        final: prev: {
          # https://github.com/NixOS/nixpkgs/pull/545349
          version = "3.14.3";
          src = fetchFromGitHub {
            owner = "aio-libs";
            repo = "aiohttp";
            tag = "v${final.version}";
            hash = "sha256-n8LH34N9V2Smqc23q/49gqRbP0U1glJAYiyPEGFtEmM=";
          };
          postPatch = prev.postPatch + ''
            # https://github.com/NixOS/nixpkgs/pull/526853
            # don't depend on coverage for tests
            substituteInPlace setup.cfg \
              --replace-fail "ignore:Couldn't import C tracer:coverage.exceptions.CoverageWarning" ""
          '';
          nativeCheckInputs = prev.nativeCheckInputs ++ [ pytest-timeout ];
        }
      );
  aiohappyeyeballs' = aiohappyeyeballs.overridePythonAttrs rec {
    # https://github.com/NixOS/nixpkgs/pull/541370/changes/e84a374a8fa5cf8dfdf2604d40c02df7a808956f
    version = "2.7.1";
    src = fetchFromGitHub {
      owner = "bdraco";
      repo = "aiohappyeyeballs";
      tag = "v${version}";
      hash = "sha256-smpdmmut4wYekVew13KZXluI71lSUdZriPejUumkLNU=";
    };
  };
  multidict' = multidict.overridePythonAttrs rec {
    version = "6.9.1";
    src = fetchFromGitHub {
      owner = "aio-libs";
      repo = "multidict";
      tag = "v${version}";
      hash = "sha256-Xe8n3Y8x5fOS+xme5pKJuiiU6y+oXosZLoEA1Rkp+Qw=";
    };
    # https://github.com/aio-libs/multidict/commit/ecc83e16512ff380b784294bdddaca169b47b1a4
    # or just remove `python -m coverage` like https://github.com/NixOS/nixpkgs/blob/6efd49fd338b7c7947843d5635620d99d017a9b5/pkgs/development/python-modules/typer/default.nix#L36
    nativeCheckInputs = [ coverage ];
  };
  propcache' =
    (propcache.override {
      setuptools = setuptools.overridePythonAttrs rec {
        # https://github.com/aio-libs/propcache/pull/225
        version = "82.0.1";
        src = fetchFromGitHub {
          owner = "pypa";
          repo = "setuptools";
          tag = "v${version}";
          hash = "sha256-M4fB+R4UNla2VlcWNhfDLvExQMpjLkPkgVsU4vg6ImU=";
        };
      };
    }).overridePythonAttrs
      rec {
        # https://github.com/NixOS/nixpkgs/pull/527386/changes/299bfeb14d0ef2bc80150375195cd176bdc66da6
        version = "0.5.2";
        src = fetchFromGitHub {
          owner = "aio-libs";
          repo = "propcache";
          tag = "v${version}";
          hash = "sha256-vn6FSdWEMk6c8Cu1mHyhZyH8ZlFK0kgYK8T7GKLHHwc=";
        };
      };
  yarl' = yarl.override {
    multidict = multidict';
    propcache = propcache';
    idna = idna';
  };
  idna' = idna.overridePythonAttrs rec {
    # https://github.com/NixOS/nixpkgs/pull/531987/changes/71bf5cc8cb35b23e1bc393533a5177898fabbfbd
    version = "3.18";
    src = fetchFromGitHub {
      owner = "kjd";
      repo = "idna";
      tag = "v${version}";
      hash = "sha256-9nLy/9PNuLSQJsf4Jes0uN695+LGjz2LXlfiZxxvGV4=";
    };
  };
  urllib3' = urllib3.overridePythonAttrs rec {
    version = "2.8.0";
    src = fetchFromGitHub {
      owner = "urllib3";
      repo = "urllib3";
      tag = version;
      hash = "sha256-/EABIEAZDr5936K5Utjlx0nsGHWsHoimqC6dGDuOJAo=";
    };
    postPatch = ""; # https://github.com/NixOS/nixpkgs/pull/523660
  };
in
{
  setuptools = setuptools.overridePythonAttrs rec {
    # https://github.com/NixOS/nixpkgs/pull/541370/changes/31b1ff3caa7f39e44d501a129652a8703ab0bb80
    version = "83.0.0";
    src = fetchFromGitHub {
      owner = "pypa";
      repo = "setuptools";
      tag = "v${version}";
      hash = "sha256-Gn2gH2LnsgeX1MvDRBbnFnI6WjkjBFItU4SelowkjBc=";
    };
  };
  cryptography = cryptography'.override {
    # not using https://github.com/NixOS/nixpkgs/issues/370936#issuecomment-6699941196 to prevent infinite recursion that caused by self-referencing
    cryptography-vectors = cryptography'.passthru.vectors.override {
      cryptography = cryptography'; # https://github.com/NixOS/nixpkgs/blob/fad2a962a45b31cd5de6312714887cff58883cd2/pkgs/development/python-modules/cryptography/vectors.nix
    };
  };
  orjson = orjson.overridePythonAttrs (
    final: _: {
      # https://github.com/NixOS/nixpkgs/pull/554025/changes/590081bb908d045d10057ea41881f6b90cbbb8ec
      version = "3.12.0";
      src = fetchFromGitHub {
        owner = "ijl";
        repo = "orjson";
        tag = final.version;
        hash = "sha256-pmp8j6035L46ejDOkz9aQnMdX48MFFmNHM3k5TW6kqM=";
      };
      cargoDeps = rustPlatform.fetchCargoVendor {
        inherit (final) pname version src;
        hash = "sha256-h0zx3D4gVvPhHX4ziXUL4eKJEKlYOAj+9wiRbV2yuRw=";
      };
    }
  );
  certifi = certifi';
  aiohttp = aiohttp';
  idna = idna';
  urllib3 = urllib3';
  aiohttp-fast-zlib = aiohttp-fast-zlib.override { aiohttp = aiohttp'; };
  aiohappyeyeballs = aiohappyeyeballs';
  yarl = yarl';
  multidict = multidict';
  propcache = propcache';
  requests = requests.override {
    idna = idna';
    urllib3 = urllib3';
    certifi = certifi';
  };
}
