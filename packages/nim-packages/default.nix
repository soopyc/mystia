final: prev: {
  nimPackages = prev.nimPackages.overrideScope (final': prev': {
    sha1 = final'.callPackage ./sha1.nix {};
    oauth = final'.callPackage ./oauth.nix {};
  });
}
