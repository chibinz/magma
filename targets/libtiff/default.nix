{ magma
, stdenv
, fetchFromGitLab
, autoconf
, automake
, libtool
, libjpeg
, lzma
, zlib
}:

stdenv.mkDerivation {
  name = "libtiff";

  src = fetchFromGitLab {
    owner = "libtiff";
    repo = "libtiff";
    rev = "c145a6c14978f73bb484c955eb9f84203efcb12e";
    hash = "sha256-70cQGtLg0ILpO1/DpaDcqKW2vSI6V7nWisjxZWqwhuc=";
  };

  buildInputs = [ autoconf automake libtool libjpeg lzma zlib ];

  enableParallelBuilding = true;

  prePatch = magma.prePatch ./patches;

  preConfigure = ''
    # Prevents `autogen.sh` from fetching configs from the internet.
    head -n 9 autogen.sh | bash
    cp ${./src/config.guess} ${./src/config.sub} config/
  '';

  configureFlags = [ "--disable-shared" ];

  postInstall = ''
    c++ -std=c++11 -I $out/include -o $out/bin/tiff_read_rgba_fuzzer \
        contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc $out/lib/libtiffxx.a \
        $out/lib/libtiff.a -lz -ljpeg -llzma

    cp -r ${./corpus} $out/corpus
  '';

  passthru = {
    programs = [ "tiff_read_rgba_fuzzer" "tiffcp" ];
    args.tiffcp = "-M @@ tmp.out";
  };
}
