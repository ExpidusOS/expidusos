{ config, lib, ... }:
let
  cfg = config.system.nixos;
in
{
  config.system = {
    nixos = {
      version = lib.mkForce "0.2.0";
      distroId = "expidus";
      distroName = "ExpidusOS";
      extraOSReleaseArgs = {
        HOME_URL = "https://expidusos.com";
        DOCUMENTATION_URL = "https://wiki.expidusos.com";
        BUG_REPORT_URL = "https://github.com/ExpidusOS/expidusos";
        VERSION_CODENAME = "willamette";
        PRETTY_NAME = "${cfg.distroName} ${cfg.release} (${cfg.codeName})";
      };
    };
    stateVersion = lib.mkForce (lib.versions.majorMinor lib.version);
  };
}
