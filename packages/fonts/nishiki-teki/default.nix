{
  lib,
  fetchzip,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (final: {
  pname = "nishiki-teki";
  version = "3.99zhh";

  src = fetchzip {
    # original url: https://umihotaru.work/nishiki-teki.zip
    # mirrored for versioning.
    url = "https://assets.soopy.moe/mirror/nishiki-teki-v${final.version}.zip";
    hash = "sha256-szKrHLUSm6z/31eneJxMYYig9MyUrwVyRUiR46PP8MI=";
    stripRoot=false;
  };

  buildPhase = ''
    local outdir=$out/share/fonts/nishiki-teki
    mkdir -p $outdir
    cp nishiki-teki.ttf $outdir/nishiki-teki.ttf
  '';

  meta = {
    description = "Unicode-based font inspired by Nishiki, with conlangs support";
    homepage = "https://umihotaru.work/";
    license = lib.licenses.ofl;

    maintainers = with lib.maintainers; [ soopyc ];
  };
})
