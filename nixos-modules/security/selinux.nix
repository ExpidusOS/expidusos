{ config, lib, pkgs, ... }:
let
  cfg = config.security.selinux;
in
{
  options.security.selinux = {
    enable = lib.mkEnableOption "SELinux" // { default = true; };
    policy = lib.mkOption {
      type = lib.types.path;
      description = "The path to the SELinux policy";
      defaultText = lib.literalExpression ''"''${pkgs.selinux-refpolicy.override { inherit (config.security.selinux) policyVersion; }}/share/selinux/refpolicy"'';
      default = "${pkgs.selinux-refpolicy.override {
        inherit (config.security.selinux) policyVersion;
      }}/share/selinux/refpolicy";
    };
    policyVersion = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      description = "The version of the SELinux policy";
      default = 33;
    };
    type = lib.mkOption {
      type = lib.types.str;
      description = "The SELinux policy type to load";
      default = "refpolicy";
    };
    mode = lib.mkOption {
      type = lib.types.enum [ "enforcing" "permissive" "disabled" ];
      description = "The enforcement mode";
      default = "permissive";
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernelPatches = [
        {
          name = "selinux";
          extraStructuredConfig = with lib.kernel; {
            SECURITY_SELINUX = yes;
            SECURITY_SELINUX_BOOTPARAM = yes;
            DEFAULT_SECURITY_APPARMOR = lib.mkForce no;
            DEFAULT_SECURITY_SELINUX = yes;
          };
          patch = null;
        }
      ];
      kernelParams = [ "security=selinux" ];
    };

    system.activationScripts.selinux = {
      deps = [ "etc" ];
      text = ''
        install -d -m0755 /var/lib/selinux
        ${lib.getExe' pkgs.policycoreutils "semodule"} -s ${cfg.type} -i ${cfg.policy}/*.pp
      '';
    };

    systemd.package = pkgs.systemd.override {
      withSelinux = true;
    };

    environment = {
      etc."selinux/config".text = ''
        SELINUX=${cfg.mode}
        SELINUXTYPE=${cfg.type}
      '';
      etc."selinux/semanage.conf".text = lib.optionalString (cfg.policyVersion != null) ''
        policy-version = ${toString cfg.policyVersion}
      '' + ''
        compiler-directory = ${pkgs.policycoreutils}/libexec/selinux/hll

        [load_policy]
        path = ${lib.getExe' pkgs.policycoreutils "load_policy"}
        [end]

        [setfiles]
        path = ${lib.getExe' pkgs.policycoreutils "setfiles"}
        args = -q -c $@ $<
        [end]

        [sefcontext_compile]
        path = ${lib.getExe' pkgs.libselinux "sefcontext_compile"}
        args = -r $@
        [end]
      '';
      systemPackages = with pkgs; [ libselinux policycoreutils ];
    };
  };
}
