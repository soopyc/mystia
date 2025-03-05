{
  description = "Just a bunch of packages";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-update-soopy = {
      url = "github:soopyc/nix-update";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      nix-update-soopy,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
      ];
      forAllSystems = fn: nixpkgs.lib.genAttrs systems (system: fn nixpkgs.legacyPackages.${system});

      treefmtEval = forAllSystems (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      packages = forAllSystems (pkgs: import ./packages/all-packages.nix { } pkgs);
      overlays.default = import ./packages/all-packages.nix;

      formatter = forAllSystems (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
      checks = forAllSystems (pkgs: {
        formatting = treefmtEval.${pkgs.system}.config.build.check self;
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = [ nix-update-soopy.packages.${pkgs.system}.default ];
        };
      });

      nixosModules = {
        fixups = import ./modules/fixups;
        vmauth = import ./modules/vmauth;
        arrpc = import ./modules/arrpc;
        bsky-pds = import ./modules/bsky-pds;
      };
    };
}
