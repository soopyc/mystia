{
  description = "Just a bunch of packages";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nix-update-soopy = {
      url = "github:soopyc/nix-update";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://nonbunary.soopy.moe/gensokyo-global"
      "https://cache.garnix.io"
    ];

    extra-trusted-public-keys = [
      "gensokyo-global:XiCN0D2XeSxF4urFYTprR+1Nr/5hWyydcETwZtPG6Ec="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };
  in {
    packages.${system} = import ./packages/all-packages.nix {} pkgs;
    overlays.default = import ./packages/all-packages.nix;
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

    devShells.${system}.default = pkgs.mkShellNoCC {
      packages = [
        inputs.nix-update-soopy.packages.${system}.default
      ];
    };

    nixosModules = {
      fixups = import ./modules/fixups;
      vmauth = import ./modules/vmauth;
      arrpc = import ./modules/arrpc;
    };
  };
}
