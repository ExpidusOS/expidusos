{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "expidus-wallpapers";
  version = "0-unstable-2025-04-03";

  src = fetchFromGitHub {
    owner = "ExpidusOS";
    repo = "wallpapers";
    rev = "6215cf183648c57977ded3838c17ba9e8d03185a";
    hash = "sha256-8OPGWFkvdrgqSKbJWPQ+1O+qJG8CnXCtd4lFiG+dZ7E=";
  };

  makeFlags = [ "prefix=${placeholder "out"}" ];
})
