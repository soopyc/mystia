{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs_20,
  pnpm_8,
  vips,
  python311,
  pkg-config,
  makeWrapper,
  fetchPnpmDeps,
  pnpmConfigHook,
}:
stdenv.mkDerivation (final: {
  pname = "bsky-pds";
  version = "0.4.204";

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "pds";
    rev = "ab53b2464d2cd24eaf8a25397f19c54b71bd6a2e";
    hash = "sha256-jYCMwHKKFIsfOgGYiKVrWtIT7atPA8NsetvfjDW05yE=";
  };
  sourceRoot = "${final.src.name}/service";

  buildInputs = [
    vips # sharp
  ];

  nativeBuildInputs = [
    nodejs_20
    pnpm_8
    makeWrapper
    pnpmConfigHook
    python311 # sharp
    pkg-config # sharp
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (final)
      pname
      version
      src
      sourceRoot
      ;
    pnpm = pnpm_8;
    fetcherVersion = 2;
    hash = "sha256-huBuxj+NGdigD+y4dKkBzyVKLruQWa4xecr1WwZ+WVw=";
  };

  buildPhase = ''
    # https://github.com/NixOS/nixpkgs/pull/296697/files#r1617595593
    # maybe instead of this hack we can just use nixpkgs' node-gyp instead?
    export npm_config_nodedir=${nodejs_20}
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

    pnpm i --production --frozen-lockfile
  '';

  installPhase = ''
    mkdir -p $out/lib/bsky-pds
    cp -r . $out/lib/bsky-pds
    makeWrapper "${lib.getExe nodejs_20}" "$out/bin/bsky-pds" \
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
