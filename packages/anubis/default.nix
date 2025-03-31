{
  lib,
  stdenv,
  buildGo124Module,
  fetchFromGitHub,
  fetchNpmDeps,
  nix-update-script,
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
  version = "1.15.0-unstable-2025-03-31";

  src = fetchFromGitHub {
    owner = "TecharoHQ";
    repo = "anubis";
    rev = "28828a2e93de32e758b62107f0af0a429b911b90";
    hash = "sha256-+zYj/8JLQDm+zSaY8IFguOQX/r22hrvrnTzL3p4+n+M=";
  };

  env.npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    hash = "sha256-P7qJWyBhqsDf51j8ctYdWbR0NiNF3GvNiW18BagTGQA=";
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

  passthru.updateScript = nix-update-script { };

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
