# mystia

just a bunch of packages.

## usage
slide `github:soopyc/mystia` into your flake inputs like so
```nix
{
  inputs = {
    # ...
    mystia.url = "github:soopyc/mystia";
    mystia.inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

then add inputs or just mystia to your specialArgs
```nix
{
  nixosConfigurations = {
    system = lib.nixosSystem {
      specialArgs = {
        inherit mystia;
      };
    };
  };
}
```

and add the overlay in your nixos config
```nix
{ mystia, pkgs, ... }:
{
  nixpkgs.overlays = [ mystia.overlays.default ];
}
```

cross your fingers and hope it works
