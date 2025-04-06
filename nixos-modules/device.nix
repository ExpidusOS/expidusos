{ lib, ... }:
{
  options.expidus.device.name = lib.mkOption {
    description = "Name of the device";
    type = lib.types.str;
  };
}
