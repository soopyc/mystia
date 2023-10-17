{stdenvNoCC}:
stdenvNoCC.mkDerivation {
  name = "staticly";
  src = ./src;

  installPhase = ''
    mkdir $out
    cp -rv $src/* $out
  '';
}
