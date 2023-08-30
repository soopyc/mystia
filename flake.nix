{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
    let
      pkgs = import nixpkgs { 
        system = "x86_64-linux";
      };
    in {
      packages.x86_64-linux = {
        default = nixpkgs.legacyPackages.x86_64-linux.hello;
        staticly = pkgs.callPackage ./staticly {};
      };
    };
}
