{
  pkgs,
  llvmPkgs,
  stdenv,
  deps,
}:

stdenv.mkDerivation {
  name = "libpng";

  src = pkgs.fetchFromGitHub {
    owner = "glennrp";
    repo = "libpng";
    rev = "a37d4836519517bdce6cb9d956092321eca3e73b";
    hash = "sha256-KCpOY1kL4eG51bUv28aw8jTjUNwr3UHAGBqAaN2eBvg=";
  };

  buildInputs = [ deps.zlib llvmPkgs.lld ];

  dontDisableStatic = true;

  configureFlags = [
    "--disable-shared"
  ];

  preConfigure = ''
    export CFLAGS="$CFLAGS -flto"
    export LDFLAGS="$LDFLAGS -fuse-ld=lld"
  '';
}
