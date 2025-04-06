{ config, lib, pkgs, inputs, ... }: {
  imports = [
    ./device.nix
    ./version.nix
    ./security/selinux.nix
  ];

  config = {
    services = {
      displayManager.cosmic-greeter.enable = true;
      desktopManager.cosmic.enable = true;
      homed.enable = true;
    };

    # Until https://github.com/NixOS/nixpkgs/pull/396105 is merged
    networking.networkmanager.plugins = lib.mkForce [];

    boot = {
      kernelPatches = [
        {
          name = "hardened";
          extraStructuredConfig = import "${inputs.nixpkgs}/pkgs/os-specific/linux/kernel/hardened/config.nix" {
            inherit lib;
            inherit (pkgs) stdenv;
            inherit (config.boot.kernelPackages.kernel) version;
          };
          patch = null;
        }
        {
          name = "lsm";
          extraStructuredConfig = with lib.kernel; {
            LSM = freeform "selinux,capability,landlock,yama,safesetid,bpf";
          };
          patch = null;
        }
      ];
      specialFileSystems."/proc" = {
        fsType = "proc";
        options = [ "hidepid=2" ];
      };
      plymouth.enable = true;
    };

    environment.systemPackages = with pkgs; [
      expidus-wallpapers
    ];

    security = {
      auditd.enable = true;
      protectKernelImage = true;
    };

    nixpkgs.overlays = [
      (import ../pkgs/default.nix)
    ];
  };
}
