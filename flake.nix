{
  description = "Just a bunch of packages";

  nixConfig = {
    extra-trusted-substituters = [
      "https://nonbunary.soopy.moe/gensokyo-global"
    ];

    extra-trusted-public-keys = [
      "gensokyo-global:XiCN0D2XeSxF4urFYTprR+1Nr/5hWyydcETwZtPG6Ec="
    ];
  };

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ... }: # @inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      packages.x86_64-linux = import ./packages/all-packages.nix {} pkgs;
      overlays.default = import ./packages/all-packages.nix;
    };
}
