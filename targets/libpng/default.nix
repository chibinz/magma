{ pkgs
, llvmPkgs
, stdenv
, deps
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
    export CXXFLAGS="$CFlAGS"
    export LDFLAGS="$LDFLAGS -fuse-ld=lld"
  '';

  postInstall = ''
    echo "#include <stdlib.h>" > $out/libpng_read_fuzzer.cc
    cat $src/contrib/oss-fuzz/libpng_read_fuzzer.cc >> $out/libpng_read_fuzzer.cc
    $CXX $CXXFLAGS -fsanitize=fuzzer -std=c++11 -I $out/include -o $out/bin/libpng_read_fuzzer -lz $LDFLAGS \
      $out/lib/libpng16.a $out/libpng_read_fuzzer.cc
  '';
}
