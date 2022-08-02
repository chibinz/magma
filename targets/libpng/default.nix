{ fetchFromGitHub
, stdenv
, driver
, zlib
}:

stdenv.mkDerivation {
  name = "libpng";

  src = fetchFromGitHub {
    owner = "glennrp";
    repo = "libpng";
    rev = "a37d4836519517bdce6cb9d956092321eca3e73b";
    hash = "sha256-KCpOY1kL4eG51bUv28aw8jTjUNwr3UHAGBqAaN2eBvg=";
  };

  buildInputs = [ zlib ];

  dontDisableStatic = true;
  configureFlags = [
    "--disable-shared"
  ];

  postInstall = ''
    # Add missing header for `malloc/free`
    echo "#include <stdlib.h>" > $out/libpng_read_fuzzer.cc
    cat $src/contrib/oss-fuzz/libpng_read_fuzzer.cc >> $out/libpng_read_fuzzer.cc

    # Link order matters here
    $CXX $CXXFLAGS -std=c++11 -I $out/include -o $out/bin/libpng_read_fuzzer -lz $LDFLAGS \
      $out/libpng_read_fuzzer.cc $out/lib/libpng16.a ${driver}
  '';
}
