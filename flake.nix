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

  outputs = {
    self,
    nixpkgs,
    nix-update-soopy,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin"];
    forAllSystems = fn: nixpkgs.lib.genAttrs systems (system: fn nixpkgs.legacyPackages.${system});
  in {
    packages = forAllSystems (pkgs: import ./packages/all-packages.nix {} pkgs);
    overlays.default = import ./packages/all-packages.nix;
    formatter = forAllSystems (pkgs: pkgs.alejandra); # FIXME: move to treefmt-nix

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShellNoCC {
        packages = [nix-update-soopy.packages.${pkgs.system}.default];
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
