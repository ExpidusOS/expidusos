pkgs: prev: with pkgs;
{
  expidus-wallpapers = callPackage ./expidus-wallpapers {};

  cosmic-comp = prev.cosmic-comp.overrideAttrs {
    separateDebugInfo = true;
    buildType = "debug";
  };

  OVMF = prev.OVMF.overrideAttrs (f: p: {
    postPatch = ''
      ${imagemagick}/bin/convert ${../logo.png} -type truecolor MdeModulePkg/Logo/Logo.bmp
    '';
  });

  libselinux = prev.libselinux.overrideAttrs (f: p: {
    version = "3.8.1";

    src = fetchurl {
      url = "${f.se_url}/${f.version}/libselinux-${f.version}.tar.gz";
      hash = "sha256-7C0nifkxFS0hwdsetLwgLOTszt402b6eNg47RSQ87iw=";
    };
  });

  libsemanage = prev.libsemanage.overrideAttrs (f: p: {
    patches = p.patches or [] ++ [
      ./libsemanage-restorecon.patch
      ./libsemanage-config-func.patch
    ];
  });

  policycoreutils = prev.policycoreutils.overrideAttrs (f: p: {
    patches = p.patches or [] ++ [
      ./policycoreutils-semanage-config.patch
    ];
  });
}
