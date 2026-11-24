{
  python3Packages,
  fetchFromGitHub,
}:

let
  frequi = python3Packages.callPackage ./frequi.nix { };
  freqtrade-client = python3Packages.callPackage ./freqtrade-client.nix { };
  dedupedDeps =
    with rec {
      inherit (python3Packages)
        ccxt
        httpcore
        starlette
        ;
      inherit (ccxt.pinnedDeps) certifi idna;
    }; rec {
      anyio = python3Packages.anyio.override { inherit idna; };
      httpx = python3Packages.httpx.override {
        inherit certifi idna anyio;
        httpcore = httpcore.override { inherit certifi; };
      };
      fastapi = python3Packages.fastapi.override { starlette = starlette.override { inherit anyio; }; };
    };
in
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "freqtrade";
  version = "2026.10";
  src = fetchFromGitHub {
    owner = "freqtrade";
    repo = "freqtrade";
    tag = finalAttrs.version;
    hash = "sha256-APolLFb1GQ+vKsv8fuB91WANRRWftuWQfCZLGTwdacM=";
  };
  pyproject = true;
  build-system = with python3Packages; [
    setuptools
    wheel
  ];
  dependencies = with python3Packages; [
    ccxt
    sqlalchemy
    (python-telegram-bot.override { inherit (dedupedDeps) httpx; })
    humanize
    cachetools
    ccxt.pinnedDeps.requests
    dedupedDeps.httpx
    ccxt.pinnedDeps.urllib3
    ccxt.pinnedDeps.certifi
    jsonschema
    scipy
    numpy
    pandas
    bottleneck
    numexpr
    ta-lib
    ft-pandas-ta
    technical
    tabulate
    (pycoingecko.override { inherit (ccxt.pinnedDeps) requests; })
    python-rapidjson
    ccxt.pinnedDeps.orjson
    jinja2
    questionary
    prompt-toolkit
    joblib
    cloudpickle
    rich
    pyarrow
    dedupedDeps.fastapi
    pydantic
    pyjwt
    websockets
    uvicorn
    psutil
    schedule
    janus
    ast-comments
    aiofiles
    ccxt.pinnedDeps.aiohttp
    ccxt.pinnedDeps.cryptography
    sdnotify
    python-dateutil
    pytz
    packaging
    freqtrade-client
  ];
  postInstall = ''
    # https://github.com/freqtrade/freqtrade/blob/064e67c42af3c4026d123990f992ac42f7ee3cde/freqtrade/commands/deploy_commands.py#L117
    ln -s ${frequi} $out/${python3Packages.python.sitePackages}/freqtrade/rpc/api_server/ui/installed
  '';
  meta.mainProgram = "freqtrade";
})
