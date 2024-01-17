# Patching original https://github.com/NixOS/nixpkgs/blob/73df0bf25118d50f312d1accb536aefa009cc1b3/pkgs/applications/version-management/forgejo/default.nix#L48
# with ~~https://github.com/NixOS/nixpkgs/pull/119942~~ latest developmental version
{
  bash,
  brotli,
  buildGo121Module,
  forgejoUnstable,
  git,
  gzip,
  lib,
  makeWrapper,
  nix-update-script,
  nixosTests,
  openssh,
  pam,
  pamSupport ? true,
  sqliteSupport ? true,
  xorg,
  runCommand,
  stdenv,
  fetchFromGitea,
  buildNpmPackage,
}: let
  frontend = buildNpmPackage {
    pname = "forgejo-frontend";
    inherit (forgejoUnstable) src version;

    npmDepsHash = "sha256-fGvf6bLA9/cCKucj0oQCZC86lnvvEqqHKHnkiCc7bT0=";

    patches = [
      ./package-json-npm-build-frontend.patch
    ];

    # override npmInstallHook
    installPhase = ''
      mkdir $out
      cp -R ./public $out/
    '';
  };
in
  buildGo121Module rec {
    vendorHash = "sha256-HujoxE6z74Pf/qoiAMepqgyoBUBuXgXNxKE/vyn3LJc=";

    # FIXME: ideally we would use a function to override stuff as described in https://nixos.org/manual/nixpkgs/unstable/#mkderivation-recursive-attributes. However, buildGoModule does not yet support this as of this commit.
    pname = "forgejoUnstable";
    _commit = "c4675549c93c30d96c04b0dfb684aea5026f8f9e";
    version = "1.21.3-dev-${builtins.substring 0 7 _commit}";

    src = fetchFromGitea {
      domain = "codeberg.org";
      owner = "forgejo";
      repo = "forgejo";
      rev = _commit;
      hash = "sha256-hXnOZF4v8+Jqyzbnsnbb/oGIWFQw5i8ERxLc1cuRk/g=";
    };

    subPackages = ["."];

    outputs = ["out" "data"];

    nativeBuildInputs = [makeWrapper];
    buildInputs = lib.optional pamSupport pam;

    patches = [
      ./static-root-path.patch
    ];

    postPatch = ''
      substituteInPlace modules/setting/setting.go --subst-var data
    '';

    tags =
      lib.optional pamSupport "pam"
      ++ lib.optionals sqliteSupport ["sqlite" "sqlite_unlock_notify"];

    ldflags = [
      "-s"
      "-w"
      "-X main.Version=${version}"
      "-X 'main.Tags=${lib.concatStringsSep " " tags}'"
    ];

    preBuild = ''
      go run build/merge-forgejo-locales.go
    '';

    postInstall = ''
      mkdir $data
      cp -R ./{templates,options} ${frontend}/public $data
      mkdir -p $out
      cp -R ./options/locale $out/locale
      wrapProgram $out/bin/gitea \
        --prefix PATH : ${lib.makeBinPath [bash git gzip openssh]}
    '';

    # $data is not available in goModules.drv and preBuild isn't needed
    overrideModAttrs = _: {
      postPatch = null;
      preBuild = null;
    };

    passthru = {
      # allow nix-update to handle npmDepsHash
      inherit (frontend) npmDeps;

      data-compressed =
        runCommand "forgejo-data-compressed" {
          nativeBuildInputs = [brotli xorg.lndir];
        } ''
          mkdir $out
          lndir ${forgejoUnstable.data}/ $out/

          # Create static gzip and brotli files
          find -L $out -type f -regextype posix-extended -iregex '.*\.(css|html|js|svg|ttf|txt)' \
            -exec gzip --best --keep --force {} ';' \
            -exec brotli --best --keep --no-copy-stat {} ';'
        '';

      tests = nixosTests.forgejo;
      updateScript = nix-update-script {};
    };

    meta = {
      description = "A self-hosted lightweight software forge";
      homepage = "https://forgejo.org";
      changelog = "https://codeberg.org/forgejo/forgejo/compare/${_commit}...v1.20.5-0";
      # changelog = "https://codeberg.org/forgejo/forgejo/releases/tag/${src.rev}";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [emilylange urandom bendlas adamcstephens (import ../maintainers/soopyc.nix)];
      broken = stdenv.isDarwin;
      mainProgram = "gitea";
    };
  }
