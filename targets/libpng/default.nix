{ magma
, stdenv
, fetchFromGitHub
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

  enableParallelBuilding = true;

  prePatch = magma.prePatch ./patches;

  configureFlags = [
    "--disable-shared"
  ];

  postInstall = ''
    # Add missing header for `malloc/free`
    sed -i '1i #include <stdlib.h>' contrib/oss-fuzz/libpng_read_fuzzer.cc

    # Link order matters here
    c++ -std=c++11 -I $out/include -o $out/bin/libpng_read_fuzzer \
      contrib/oss-fuzz/libpng_read_fuzzer.cc $out/lib/libpng16.a -lz
  '';
}
