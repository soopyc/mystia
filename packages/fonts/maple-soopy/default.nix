{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation (final: {
  pname = "maple-soopy";
  version = "7.9+soopy-2026-04-20.03";

  src = fetchzip {
    url = "https://github.com/soopyc/maple-soopy/releases/download/v1776615501/MapleSoopyNL-NF-CN.zip";
    hash = "sha256-WZo4Wj+wdM9jM9jZ1ljGUewd+vtzZNaocNDSc6RiI+E=";

    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall

    install -Dm444 -t "$out/share/fonts/truetype/${final.pname}/" *.ttf

    runHook postInstall
  '';

  meta = {
    description = "customized maple-mono";
    maintainers = lib.singleton lib.maintainers.soopyc;
    license = lib.licensesSpdx."OFL-1.1";
  };
})
