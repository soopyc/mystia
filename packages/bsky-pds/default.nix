{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs_24, # FIXME: nodejs 24 issue with ffi with better-sqlite3
  pnpm_11,
  python311,
  makeWrapper,
  fetchPnpmDeps,
  pnpmConfigHook,
}:
stdenv.mkDerivation (final: {
  pname = "bsky-pds";
  version = "0.5.51+ca6b5f01"; # 0.4.5051
  # upstream versioning is like this to accomodate their (arguably terrible) auto-update legacy code

  patchFlags = "-p2";
  patches = [
    ./update-pnpm-to-11.diff
  ];

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "pds";
    rev = "ca6b5f015f77e4d9140614ff4d073e60e186d6d9";
    hash = "sha256-p8bZW/0BO2l7Xnqxsf6r0btCZzM1ODpWbsOvwQ7n3zc=";
  };
  sourceRoot = "${final.src.name}/service";

  nativeBuildInputs = [
    nodejs_24
    pnpm_11
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
    pnpm = pnpm_11;
    fetcherVersion = 5;
    hash = "sha256-UEaHTFOXJAzU+7Ow97aE7ixFWY/72V62Ujk5/BW+qlc=";
  };

  buildPhase = ''
    # https://github.com/NixOS/nixpkgs/pull/296697/files#r1617595593
    # maybe instead of this hack we can just use nixpkgs' node-gyp instead?
    export npm_config_nodedir=${nodejs_24}
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
    makeWrapper "${lib.getExe nodejs_24}" "$out/bin/bsky-pds" \
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
