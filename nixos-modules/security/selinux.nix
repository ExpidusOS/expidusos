{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.security.selinux;
in
{
  options.security.selinux = {
    enable = lib.mkEnableOption "SELinux" // {
      default = true;
    };
    policy = lib.mkOption {
      type = lib.types.path;
      description = "The path to the SELinux policy";
      defaultText = lib.literalExpression ''''${pkgs.selinux-refpolicy.override { inherit (config.security.selinux) policyVersion; }}'';
      default = "${
        pkgs.selinux-refpolicy.override {
          inherit (config.security.selinux) policyVersion;
        }
      }";
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
      type = lib.types.enum [
        "enforcing"
        "permissive"
        "disabled"
      ];
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
        cmd="${lib.getExe' pkgs.policycoreutils "semodule"} -s ${cfg.type} -i ${cfg.policy}/share/selinux/${cfg.type}/*.pp"
        skipSELinuxActivation=0

        if [ -e /var/lib/selinux/activate-check ]; then
          if [ "$(cat /var/lib/selinux/activate-check)" == "$cmd" ]; then
            skipSELinuxActivation=1
          fi
        fi

        if [ -z $skipSELinuxActivation ]; then
          eval "$cmd"
          echo "$cmd" >/var/lib/selinux/activate-check
        fi
      '';
    };

    system.build.selinux-policy = pkgs.stdenv.mkDerivation {
      name = "selinux-${cfg.type}-modules.img";

      nativeBuildInputs = with pkgs; [
        policycoreutils
        squashfsTools
      ];

      buildCommand = ''
        mkdir -p files/etc/selinux files/var/lib/selinux/final
        printf "${config.environment.etc."selinux/semanage.conf".text}" > config
        semodule --config config -p files -s ${cfg.type} -i ${cfg.policy}/share/selinux/${cfg.type}/*.pp || true
        mksquashfs files $out -b 1048576 -processors $NIX_BUILD_CORES
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
      etc."selinux/semanage.conf".text =
        lib.optionalString (cfg.policyVersion != null) ''
          policy-version = ${toString cfg.policyVersion}
        ''
        + ''
          compiler-directory = ${pkgs.policycoreutils}/libexec/selinux/hll

          [load_policy]
          path = ${lib.getExe' pkgs.policycoreutils "load_policy"}
          [end]

          [setfiles]
          path = ${lib.getExe' pkgs.policycoreutils "setfiles"}
          args = -q -v -c $@ $<
          [end]

          [sefcontext_compile]
          path = ${lib.getExe' pkgs.libselinux "sefcontext_compile"}
          args = -v -r $@
          [end]
        '';
      systemPackages = with pkgs; [
        libselinux
        policycoreutils
      ];
    };
  };
}
