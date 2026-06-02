{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs_24,
  pnpm_8,
  python311,
  makeWrapper,
  fetchPnpmDeps,
  pnpmConfigHook,
}:
stdenv.mkDerivation (final: {
  pname = "bsky-pds";
  version = "0.4.219";

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "pds";
    rev = "eb46a2e156e8e18709de6dfa6beae09c330e1eeb";
    hash = "sha256-j7XNZYZHHj5HdtEuTAhNU9TD7S7eMILMflZJn0nDVaY=";
  };
  sourceRoot = "${final.src.name}/service";

  nativeBuildInputs = [
    nodejs_24
    pnpm_8
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
    pnpm = pnpm_8;
    fetcherVersion = 3;
    hash = "sha256-2HlqgsihpKV2U+KRRsAqVRaiRHmUZXdXCIpESSHz+3s=";
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
