{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  pnpm_8,
  vips,
  python311,
  pkg-config,
  makeWrapper,
}:
stdenv.mkDerivation (final: {
  pname = "bsky-pds";
  version = "0.4.138";

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "pds";
    rev = "3e82147ab1e649d403cd3065ebb500139c7708a2";
    hash = "sha256-4HsHKCUe4Em7HgCi4RDN09j+thcgojBBnoLIpJg5plE=";
  };
  sourceRoot = "${final.src.name}/service";

  buildInputs = [
    vips # sharp
  ];

  nativeBuildInputs = [
    nodejs
    pnpm_8.configHook
    makeWrapper
    python311 # sharp
    pkg-config # sharp
  ];

  pnpmDeps = pnpm_8.fetchDeps {
    inherit (final)
      pname
      version
      src
      sourceRoot
      ;
    hash = "sha256-DkNLeWL96oxF3JSYFhACVBQwuZIwEBYPnjhilw6bYhU=";
  };

  buildPhase = ''
    # https://github.com/NixOS/nixpkgs/pull/296697/files#r1617595593
    # maybe instead of this hack we can just use nixpkgs' node-gyp instead?
    export npm_config_nodedir=${nodejs}
    # we need to run this because pnpmDeps doesn't run scripts.
    (
      cd node_modules/.pnpm/node_modules/sharp
      pnpm run install
    )
    (
      cd node_modules/.pnpm/node_modules/better-sqlite3
      pnpm run build-release
      # regular `install` has prebuild-install which does an unnecessary request to github api
    )
    (
      cd node_modules/.pnpm/node_modules/cbor-extract
      pnpm run install
    )

    pnpm i --production --frozen-lockfile
  '';

  installPhase = ''
    mkdir -p $out/lib/bsky-pds
    cp -r . $out/lib/bsky-pds
    makeWrapper "${lib.getExe nodejs}" "$out/bin/bsky-pds" \
      --add-flags "$out/lib/bsky-pds/index.js" \
      --set-default NODE_ENV production
  '';

  meta = {
    description = "Official TypeScript implementation of the Bluesky personal data server";
    homepage = "https://github.com/bluesky-social/pds";
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = with lib.maintainers; [ soopyc ];

    mainProgram = "bsky-pds";
  };
})
