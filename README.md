[![Garnix CI build status](https://img.shields.io/endpoint?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Fsoopyc%2Fmystia%3Fbranch%3Dmistress&label=Garnix%20CI&color=%2300AAFF)](https://opencollective.com/garnix_io)

<hr/>

# mystia

just a bunch of packages.

## what's inside?
run `nix flake show github:soopyc/mystia`

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
