{
  python3Packages,
  fetchFromGitHub,
}:

let
  frequi = python3Packages.callPackage ./frequi.nix { };
  freqtrade-client = python3Packages.callPackage ./client.nix { };
in
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "freqtrade";
  version = "2026.6";
  src = fetchFromGitHub {
    owner = "freqtrade";
    repo = "freqtrade";
    tag = finalAttrs.version;
    hash = "sha256-phxhnwijuvsPsRGsGxOp+RNLNBOIVXU3siBC+O9QJLg=";
  };
  pyproject = true;
  build-system = with python3Packages; [
    setuptools
    wheel
  ];
  dependencies = with python3Packages; [
    ccxt
    sqlalchemy
    python-telegram-bot
    humanize
    cachetools
    requests
    httpx
    urllib3
    jsonschema
    scipy
    numpy
    pandas
    ta-lib
    ft-pandas-ta
    technical
    tabulate
    pycoingecko
    python-rapidjson
    orjson
    jinja2
    questionary
    prompt-toolkit
    joblib
    rich
    pyarrow
    fastapi
    pydantic
    pyjwt
    websockets
    uvicorn
    psutil
    schedule
    janus
    ast-comments
    aiofiles
    aiohttp
    cryptography
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
