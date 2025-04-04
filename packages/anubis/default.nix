{
  lib,
  stdenv,
  buildGo124Module,
  fetchFromGitHub,
  fetchNpmDeps,
  unstableGitUpdater,
  # asset build-time dependencies
  nodejs,
  npmHooks,
  esbuild,
  gzip,
  zstd,
  brotli,
}:
buildGo124Module (finalAttrs: {
  pname = "anubis";
  version = "1.15.2-unstable-2025-04-03";

  src = fetchFromGitHub {
    owner = "TecharoHQ";
    repo = "anubis";
    rev = "a230a58a1d6d11d50846c6f788d3c04a42f2c6ce";
    hash = "sha256-573sYGUJHarlafImX3lhiyPvhse9gqa/02BsuKJwV6Q=";
  };

  env.npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    hash = "sha256-QrW0grgNRZRum2mCec86Za1UV4R5QSRlhjVYFsZDwY8=";
  };

  vendorHash = "sha256-Rcra5cu7zxGm2LhL2x9Kd3j/uQaEb8OOh/j5Rhh8S1k=";

  subPackages = [
    "cmd/anubis"
  ];

  ldflags =
    [
      "-s"
      "-w"
      "-X=github.com/TecharoHQ/anubis.Version=v${finalAttrs.version}"
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      "-extldflags=-static"
    ];

  nativeBuildInputs = [
    esbuild
    gzip
    zstd
    brotli
    nodejs
    npmHooks.npmConfigHook
  ];

  overrideModAttrs = lib.const {
    # avoid building assets when only vendoring the deps
    preBuild = "";
  };

  preBuild = ''
    patchShebangs --build web xess
    npm run assets
  '';

  preCheck = ''
    export DONT_USE_NETWORK=1
  '';

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    description = "Weighs the soul of incoming HTTP requests using proof-of-work to stop AI crawlers";
    homepage = "https://github.com/TecharoHQ/anubis/";
    changelog = "https://github.com/TecharoHQ/anubis/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      knightpp
      soopyc
    ];
    mainProgram = "anubis";
  };
})
