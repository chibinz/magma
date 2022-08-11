{ magma
, stdenv
, fetchFromGitHub
, autoconf
, automake
, libtool
, lzma
, pkg-config
, zlib
}:

stdenv.mkDerivation rec {
  name = "libxml2";

  src = fetchFromGitHub {
    owner = "GNOME";
    repo = "libxml2";
    rev = "ec6e3efb06d7b15cf5a2328fabd3845acea4c815";
    hash = "sha256-5IGX77c2/BkyJWTyIoPKPs/TZ/2DQ4lpPdzKgogKWPY=";
  };

  buildInputs = [ autoconf automake libtool lzma pkg-config zlib ];

  enableParallelBuilding = true;

  prePatch = magma.prePatch ./patches;

  configureFlags = [
    "--prefix=$out"
    "--disable-shared"
    "--with-http=no"
    "--with-python=no"
    "--with-lzma=yes"
    "--with-threads=no"
  ];

  configurePhase = ''
    ./autogen.sh ${builtins.concatStringsSep " " configureFlags}
  '';

  extras = [
    "libxml2_xml_read_memory_fuzzer"
    "libxml2_xml_reader_for_file_fuzzer"
  ];
  programs = [
    "xmllint"
  ] ++ extras;

  postInstall = ''
    cp xmllint $out/bin

    for f in ${builtins.concatStringsSep " " extras}; do
        c++ -std=c++11 -I ${./src} -I $out/include/libxml2 -o $out/$f \
          ${./src}/$f.cc $out/lib/libxml2.a -lz -llzma
    done
  '';
}
