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
    forgejo-unstable = pkgs.lib.warn "the forgejo-unstable package is deprecated, please use forgejoUnstable instead." callPackage ./forgejo {};
    forgejoUnstable = callPackage ./forgejo {};
    nitterExperimental = callPackage ./nitter {};
  };
in
  packages
