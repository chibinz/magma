{ pkgs
, llvmPkgs
, stdenv
, fuzzer
}:

fuzzer.stdenv.mkDerivation {
  name = "libpng";

  src = pkgs.fetchFromGitHub {
    owner = "glennrp";
    repo = "libpng";
    rev = "a37d4836519517bdce6cb9d956092321eca3e73b";
    hash = "sha256-KCpOY1kL4eG51bUv28aw8jTjUNwr3UHAGBqAaN2eBvg=";
  };

  buildInputs = [ pkgs.zlib ];

  dontDisableStatic = true;
  configureFlags = [
    "--disable-shared"
  ];

  preConfigure = ''
    export CC=${fuzzer.cc}
    export CXX=${fuzzer.cxx}
  '' + fuzzer.envConfigure;

  postInstall = ''
    echo "#include <stdlib.h>" > $out/libpng_read_fuzzer.cc
    cat $src/contrib/oss-fuzz/libpng_read_fuzzer.cc >> $out/libpng_read_fuzzer.cc
    $CXX $CXXFLAGS -std=c++11 -I $out/include -o $out/bin/libpng_read_fuzzer -lz $LDFLAGS \
      $out/libpng_read_fuzzer.cc $out/lib/libpng16.a ${fuzzer.lib}
  '';
}
