pkgs: let
  pkgs' = pkgs.nimPackages;
in rec {
  nimSha1 = pkgs'.callPackage ./sha1.nix {};
  nimOauth = pkgs'.callPackage ./oauth.nix {sha1Package = nimSha1;};
  nitterExperimental = pkgs'.callPackage ./nitter {oauthPackage = nimOauth;};
}
