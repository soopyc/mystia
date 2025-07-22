# Shamefully copied from https://github.com/getchoo/nix-exprs/commit/584fab5b00d5d6016ba11a30c8e31a6314a5ce65
# and https://github.com/Scrumplex/pkgs/blob/d85a96f9d697baea9127fe20611c500c7b83b1d2/pkgs/all-packages.nix
self: final: prev:
let
  callPackage = final.callPackage or (prev.lib.callPackageWith (prev // packages));
  pkgs = if (final != { }) then final else prev;
  lib = pkgs.lib;

  packages = {
    staticly = callPackage ./staticly { };
    constanze = callPackage ./constanze { };
    nitterStable = lib.warn "mystia: the nitterStable package is unmaintained and deprecated. please use the package in nixpkgs instead." pkgs.nitter;
    bsky-pds = callPackage ./bsky-pds { };
    s3-listing = callPackage ./s3-listing { };
    anubis = lib.warn "mystia: due to maintenance burden, anubis is now dropped from mystia. sorry. please switch to the upstream nixpkgs package instead." pkgs.anubis;

    # fonts
    nishiki-teki = callPackage ./fonts/nishiki-teki { };

    # extern
    anubis-unix = lib.warn "mystia: the anubis-unix package is removed since all functionality was merged to upstream. please use the package in nixpkgs instead." pkgs.anubis;
  };
in
packages
