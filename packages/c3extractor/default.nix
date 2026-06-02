{
  lib,
  stdenv,
  fetchFromGitHub,
  clang,
}:

stdenv.mkDerivation (final: {
  pname = "c3extractor";
  version = "unstable-2025-11-30";

  src = fetchFromGitHub {
    owner = "spiiiizzzz";
    repo = "c3extractor";
    rev = "f49c48db6e0067638dbb0cb714ee4109749b9c3b";
    hash = "sha256-zy27mIPRhJaN3ORp5nD0DHvKyy/xpLjEPJYdYdS622Q=";
  };

  # gcc doesn't work, neither 14 or 15. i don't have enough time to figure out why.
  nativeBuildInputs = [
    clang
  ];

  buildPhase = ''
    runHook preBuild

    clang main.c -o c3extractor

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm555 c3extractor $out/bin/c3extractor

    runHook postInstall
  '';

  meta = {
    maintainers = with lib.maintainers; [ soopyc ];
    description = "asset extractor for games made with Construct 3";
    license = lib.licensesSpdx."GPL-3.0";
    mainProgram = "c3extractor";
  };
})
