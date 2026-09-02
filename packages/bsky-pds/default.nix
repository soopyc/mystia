{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs_22, # FIXME: nodejs 24 issue with ffi with better-sqlite3
  pnpm_10,
  python311,
  makeWrapper,
  fetchPnpmDeps,
  pnpmConfigHook,
}:
stdenv.mkDerivation (final: {
  pname = "bsky-pds";
  version = "0.5.27+edc4e8b"; # 0.4.5027
  # upstream versioning is like this to accomodate their (arguably terrible) auto-update legacy code

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "pds";
    rev = "edc4e8b2875cf577df036d512f3008fa2b1eca1c";
    hash = "sha256-LZoLKjWedxnorfaoNoM5363tSzOpphU/f+u/vOkhlKA=";
  };
  sourceRoot = "${final.src.name}/service";

  nativeBuildInputs = [
    nodejs_22
    pnpm_10
    makeWrapper
    pnpmConfigHook
    python311 # node-gyp
    # pkg-config # node-gyp?
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (final)
      pname
      version
      src
      sourceRoot
      ;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-a6hnQXPK0+mhOnvlDwOdSiyjpXZ6oB+j9HG/bh9I9D0=";
  };

  buildPhase = ''
    # https://github.com/NixOS/nixpkgs/pull/296697/files#r1617595593
    # maybe instead of this hack we can just use nixpkgs' node-gyp instead?
    export npm_config_nodedir=${nodejs_22}
    # we need to run this because pnpmDeps doesn't run scripts.
    (
      cd node_modules/.pnpm/node_modules/better-sqlite3
      pnpm run build-release
      # regular `install` has prebuild-install which does an unnecessary request to github api
    )

    pnpm i --production --frozen-lockfile
  '';

  installPhase = ''
    mkdir -p $out/lib/bsky-pds
    cp -r . $out/lib/bsky-pds
    makeWrapper "${lib.getExe nodejs_22}" "$out/bin/bsky-pds" \
      --add-flags "$out/lib/bsky-pds/index.ts" \
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
