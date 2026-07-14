{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs_24,
  pnpm_10,
  python311,
  makeWrapper,
  fetchPnpmDeps,
  pnpmConfigHook,
}:
stdenv.mkDerivation (final: {
  pname = "bsky-pds";
  version = "0.5.9"; # 0.4.5009
  # upstream versioning is like this to accomodate their (arguably terrible) auto-update legacy code

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "pds";
    rev = "f8de5f08900c42023b01a4d10995556f16d05145";
    hash = "sha256-PLNKUmEPgYmDDzYYWQvMKPq82RI96exQyAsfamZa2SE=";
  };
  sourceRoot = "${final.src.name}/service";

  nativeBuildInputs = [
    nodejs_24
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
    hash = "sha256-9dxW05u5LmTiEluqoNfQQ7NqjcLAFYOqsfOZKv1ud2I=";
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
