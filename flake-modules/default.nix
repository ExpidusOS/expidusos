{ inputs, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    let
      inherit (pkgs) lib;

      cfg = config.expidus;
      genBuilds =
        fn:
        lib.listToAttrs (
          lib.flatten (
            lib.map (
              device:
              lib.map (
                flavor:
                lib.nameValuePair "${device}-${flavor}" (fn {
                  inherit device flavor;
                })
              ) cfg.flavors
            ) cfg.devices
          )
        );
    in
    {
      options.expidus = {
        devices = lib.mkOption {
          description = "Devices to configure";
          type = with lib.types; listOf str;
          default = [ "qemu" ];
        };
        flavors = lib.mkOption {
          description = "Build flavors";
          type = with lib.types; listOf str;
          default = [ "demo" ];
        };
        build = lib.mkOption {
          default = { };
          description = ''
            Attribute set of derivations used to set up the system.
          '';
          type =
            with lib.types;
            types.submoduleWith {
              modules = [
                {
                  freeformType = lazyAttrsOf (uniq unspecified);
                }
              ];
            };
        };
      };

      config.expidus.build = genBuilds (
        { device, flavor }:
        let
          expidus = inputs.nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs;
            };
            modules = [
              ../nixos-modules/default.nix
              ../nixos-modules/devices/${device}
              ../nixos-modules/flavors/${flavor}
              inputs.nixos-cosmic.nixosModules.default
              {
                nixpkgs.localSystem = {
                  inherit (pkgs) system;
                };
              }
            ];
          };
        in
        expidus.config.system.build.default
        // {
          inherit (expidus) config options;
        }
      );
    };
}
