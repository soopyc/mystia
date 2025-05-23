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
  version = "1.18.0-unstable-2025-05-22";

  # TODO: update this to match upstream

  src = fetchFromGitHub {
    owner = "TecharoHQ";
    repo = "anubis";
    rev = "c78d830ecb28b0bc56bce2da4541634dec24b3a0";
    hash = "sha256-gIjAHXjWG2aP+bNMKT9+HmWho26pc/q0KOpptvIPgE0=";
  };

  env.npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    hash = "sha256-dJrOzSe3RWhtF76BTqm3tevzycvjdHO8gIEUW8mXi4Y=";
  };

  vendorHash = "sha256-iIzeyiQrFJCcld0DfpJ9uhCQBCMyRGtEU/sjU6e6FYQ=";

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
