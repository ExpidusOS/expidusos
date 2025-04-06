{
  inputs = {
    nixpkgs.url = "github:ExpidusOS/nixpkgs/expidus";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default-linux";
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  nixConfig = {
    extra-substituters = [ "https://cosmic.cachix.org/" ];
    extra-trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-parts,
      systems,
      nixos-cosmic,
      nixos-hardware,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { inputs, ... }:
      {
        systems = import inputs.systems;

        imports = [
          inputs.flake-parts.flakeModules.flakeModules
          ./flake-modules/default.nix
        ];

        flake = {
          flakeModules.default = ./flake-modules/default.nix;
          nixosModules.default = ./nixos-modules/default.nix;
          overlays.default = import ./pkgs/default.nix;
        };

        perSystem =
          {
            system,
            config,
            pkgs,
            inputs',
            ...
          }:
          {
            _module.args.pkgs = import inputs.nixpkgs {
              localSystem = { inherit system; };
              overlays = [
                inputs.nixos-cosmic.overlays.default
                (import ./pkgs/default.nix)
              ];
              config = { };
              inherit (inputs'.nixpkgs) lib;
            };

            legacyPackages = pkgs;

            packages = config.expidus.build;
          };
      }
    );
}
