{ config, lib, pkgs, inputs, ... }: {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
  ];

  config = {
    boot = {
      plymouth.logo = ../../../logo.png;
      kernelPackages = pkgs.linuxPackages_6_13;
    };

    expidus.device.name = lib.mkForce "qemu";

    system.build.default = config.system.build.vm;

    virtualisation = {
      qemu.options = lib.mkBefore [
        "-device virtio-gpu-gl"
        "-boot splash=${../../../logo.png}"
      ];
      tpm.enable = true;
    };
  };
}
