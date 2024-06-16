# via https://github.com/NixOS/nixpkgs/blob/cab3fd4d50a05becce0e4df3779c8d1b3e23586f/pkgs/by-name/ni/nitter/package.nix
{
  lib,
  buildNimPackage,
  fetchFromGitHub,
  nixosTests,
  substituteAll,
  unstableGitUpdater,
}:
buildNimPackage (finalAttrs: prevAttrs: {
  pname = "nitter";
  version = "unstable-2023-11-01";

  src = fetchFromGitHub {
    owner = "zedeus";
    repo = "nitter";
    rev = "b62d73dbd373f08af07c7a79efcd790d3bc1a49c";
    hash = "sha256-yCD7FbqWZMY0fyFf9Q3Ka06nw5Ha7jYLpmPONAhEVIM=";
  };

  lockFile = ./lock.json;

  patches = [
    (substituteAll {
      src = ./nitter-version.patch;
      inherit (finalAttrs) version;
      inherit (finalAttrs.src) rev;
      url = builtins.replaceStrings ["archive" ".tar.gz"] ["commit" ""] finalAttrs.src.url;
    })
  ];

  postBuild = ''
    nim compile ${toString finalAttrs.nimFlags} -r tools/gencss
    nim compile ${toString finalAttrs.nimFlags} -r tools/rendermd
  '';

  postInstall = ''
    mkdir -p $out/share/nitter
    cp -r public $out/share/nitter/public
  '';

  passthru = {
    tests = {inherit (nixosTests) nitter;};
    updateScript = unstableGitUpdater {
      branch = "guest_accounts";
    };
  };

  meta = with lib; {
    homepage = "https://github.com/zedeus/nitter";
    description = "Alternative Twitter front-end";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [erdnaxe infinidoge soopyc];
    mainProgram = "nitter";
  };
})
