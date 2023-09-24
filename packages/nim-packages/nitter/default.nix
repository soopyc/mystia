# via https://github.com/NixOS/nixpkgs/blob/nixos-23.05/pkgs/servers/nitter/default.nix

{ lib
, oauthPackage ? nimPackages.oauth
, fetchFromGitHub
, nimPackages
, nixosTests
, substituteAll
, unstableGitUpdater
}:

nimPackages.buildNimPackage rec {
  pname = "nitter";
  version = "experimental-2023-09-19+guest_accounts";

  src = fetchFromGitHub {
    owner = "zedeus";
    repo = "nitter";
    rev = "537af7fd5e846e614315fbbff8741d3c7f0c74ba";
    hash = "sha256-0D1y9lgB+7N0XFAG1IBXIzSoGoHDmfYvf70gGK8xkTw=";
  };

  patches = [
    (substituteAll {
      src = ./nitter-version.patch;
      inherit version;
      inherit (src) rev;
      url = builtins.replaceStrings [ "archive" ".tar.gz" ] [ "commit" "" ] src.url;
    })
  ];

  buildInputs = with nimPackages; [
    flatty
    jester
    jsony
    karax
    markdown
    nimcrypto
    oauthPackage
    packedjson
    redis
    redpool
    sass
    supersnappy
    zippy
  ];

  nimBinOnly = true;

  postBuild = ''
    nim c --hint[Processing]:off -r tools/gencss
    nim c --hint[Processing]:off -r tools/rendermd
  '';

  postInstall = ''
    mkdir -p $out/share/nitter
    cp -r public $out/share/nitter/public
  '';

  passthru = {
    tests = { inherit (nixosTests) nitter; };
    updateScript = unstableGitUpdater {};
  };

  meta = with lib; {
    homepage = "https://github.com/zedeus/nitter";
    description = "Alternative Twitter front-end";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ erdnaxe infinidoge (import ../../maintainers/soopyc.nix)];
    mainProgram = "nitter";
  };
}
