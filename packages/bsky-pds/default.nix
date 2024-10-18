{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  pnpm_9,
  vips,
  python3,
  pkg-config,
  makeWrapper,
}:
stdenv.mkDerivation (final: {
  pname = "bsky-pds";
  version = "0.4.59";

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "pds";
    rev = "v${final.version}";
    hash = "sha256-E4SoaLvDaHqOtZ2yExjyK6Z7Bkah6BsCFJd7cvxSwM4=";
  };
  sourceRoot = "${final.src.name}/service";

  buildInputs = [
    vips # sharp
  ];

  nativeBuildInputs = [
    nodejs
    pnpm_9.configHook
    makeWrapper
    python3 # sharp
    pkg-config # sharp
  ];

  pnpmDeps = pnpm_9.fetchDeps {
    inherit (final) pname version src sourceRoot;
    hash = "sha256-puUVL1v372Tko8IlFM+uspuUEJgQuV49+jITTvO4OH0=";
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
    # do we need to manually install cbor-extract here?
    # actually we'll do it just in case
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
      --set-default NODE_ENV production # i don't know how much this affects things
  '';

  meta = {
    description = "TypeScript implementation of the Bluesky personal data server";
    homepage = "https://github.com/bluesky-social/pds";
    license = with lib.licenses; [asl20 mit];
    maintainers = with lib.maintainers; [soopyc];

    mainProgram = "bsky-pds";
  };
})
