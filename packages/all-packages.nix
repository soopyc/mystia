# Shamefully copied from https://github.com/getchoo/nix-exprs/commit/584fab5b00d5d6016ba11a30c8e31a6314a5ce65
# and https://github.com/Scrumplex/pkgs/blob/d85a96f9d697baea9127fe20611c500c7b83b1d2/pkgs/all-packages.nix
final: prev: let
  callPackage = final.callPackage or (prev.lib.callPackageWith (prev // packages));
  pkgs =
    if (final != {})
    then final
    else prev;

  packages = {
    staticly = callPackage ./staticly {};
    constanze = callPackage ./constanze {};
    forgejo-unstable = pkgs.lib.warn "the forgejo-unstable package is deprecated, please use forgejoUnstable instead." callPackage ./forgejo {};
    forgejoUnstable = pkgs.lib.warn "the forgejoUnstable package is deprecated and is now frozen at this commit. If you would like to move back to a stable release, please do so after Forgejo v1.22.0. If you would like to continue using unstable packages, please do it of your accord. This package will be completely removed after Forgejo stable release v1.22.0." callPackage ./forgejo {};
    nitterExperimental = callPackage ./nitter {};
  };
in
  packages
