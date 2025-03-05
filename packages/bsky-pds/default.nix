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
  version = "0.4.98";

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "pds";
    rev = "93e876e553315a6ba51a75968208d33bf63e7773";
    hash = "sha256-8+pY0IwzFMN6gD+IptzuljXY58L0xXMAeP/v/rfPyIo=";
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
    hash = "sha256-JaZ7PVQttuqiU+fltB4/sW/2euePhq12RqsV8gqeUSc=";
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
