{
  inputs = {
    main.url = "path:../."; # thanks ctp-nix

    nixpgks.url = "github:NixOS/nixpkgs/nixos-unstable";
    nuscht-search.url = "github:NuschtOS/search";
    nuscht-search.inputs.nixpkgs.follows = "nixpgks";
  };

  outputs =
    {
      main,
      nixpgks,
      nuscht-search,
      ...
    }:
    let
      lib = nixpgks.lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = lib.genAttrs systems;

      msnv = "2.26";
      warnIfUnsupported =
        if lib.versionAtLeast builtins.nixVersion msnv then
          lib.id
        else
          lib.warn "This flake may not work on versions older than ${msnv}.";
    in
    warnIfUnsupported {
      packages = forAllSystems (system: {
        search = nuscht-search.packages.${system}.mkSearch {
          modules = [
            { _module.args.pkgs = nixpgks.legacyPackages.${system}; }
          ] ++ builtins.attrValues main.nixosModules;
          urlPrefix = "https://github.com/soopyc/mystia/blob/master/";
        };
      });
    };
}
