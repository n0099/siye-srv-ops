{
  callPackage,
  fetchFromGitHub,
  buildPythonApplication,
  setuptools,
  wheel,
  ccxt,
  sqlalchemy,
  python-telegram-bot,
  humanize,
  cachetools,
  requests,
  httpx,
  urllib3,
  jsonschema,
  numpy,
  pandas,
  ta-lib,
  ft-pandas-ta,
  technical,
  tabulate,
  pycoingecko,
  python-rapidjson,
  orjson,
  jinja2,
  questionary,
  prompt-toolkit,
  joblib,
  rich,
  pyarrow,
  fastapi,
  pydantic,
  pyjwt,
  websockets,
  uvicorn,
  psutil,
  schedule,
  janus,
  ast-comments,
  aiofiles,
  aiohttp,
  cryptography,
  sdnotify,
  python-dateutil,
  pytz,
  packaging,
  python,
}:

let
  frequi = callPackage ./frequi.nix { };
  freqtrade-client = callPackage ./client.nix { };
in
buildPythonApplication (finalAttrs: {
  pname = "freqtrade";
  version = "2026.5.1";
  src = fetchFromGitHub {
    owner = "freqtrade";
    repo = "freqtrade";
    tag = finalAttrs.version;
    hash = "sha256-j2yQ9gpNMrPPPrkgNclMpBs9uU2TD1Tf1eDKtrLlbGA=";
  };
  pyproject = true;
  build-system = [
    setuptools
    wheel
  ];
  dependencies = [
    ccxt
    sqlalchemy
    python-telegram-bot
    humanize
    cachetools
    requests
    httpx
    urllib3
    jsonschema
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
    ln -s ${frequi} $out/${python.sitePackages}/freqtrade/rpc/api_server/ui/installed # https://github.com/freqtrade/freqtrade/blob/064e67c42af3c4026d123990f992ac42f7ee3cde/freqtrade/commands/deploy_commands.py#L117
  '';
  meta.mainProgram = "freqtrade";
})
