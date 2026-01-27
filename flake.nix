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
    }@inputs:
    let
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
      ];
      forAllSystems = fn: nixpkgs.lib.genAttrs systems (system: fn nixpkgs.legacyPackages.${system});

      treefmtEval = forAllSystems (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      packages = forAllSystems (pkgs: import ./packages/all-packages.nix inputs { } pkgs);
      overlays.default = import ./packages/all-packages.nix inputs;

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
        fixups = lib.modules.importApply ./modules/fixups { };
        vmauth = lib.modules.importApply ./modules/vmauth { };
        arrpc = lib.modules.importApply ./modules/arrpc { };
        bsky-pds = lib.modules.importApply ./modules/bsky-pds { };
        mautrix-discord = lib.modules.importApply ./modules/mautrix-discord.nix {};
        anubis = lib.modules.importApply ./modules/anubis { inherit self; };
      };

      nixosTests = forAllSystems (pkgs: {
        anubis = pkgs.callPackage ./tests/anubis.nix { } {
          module = self.nixosModules.anubis;
        };
      });
    };
}
