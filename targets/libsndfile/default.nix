{ magma
, stdenv
, driver
, fetchFromGitHub
, autoconf
, autogen
, automake
, alsa-lib
, flac
, lame
, libogg
, libtool
, libvorbis
, libopus
, mpg123
, pkg-config
, python3
}:

stdenv.mkDerivation {
  name = "libsndfile";

  src = fetchFromGitHub {
    owner = "libsndfile";
    repo = "libsndfile";
    rev = "86c9f9eb7022d186ad4d0689487e7d4f04ce2b29";
    hash = "sha256-qt4M9zLqUKqs/V1FplsQU0DVPAYfncity06HN0394EY=";
  };

  buildInputs = [
    autoconf
    autogen
    automake
    alsa-lib
    flac
    lame
    libogg
    libtool
    libvorbis
    libopus
    mpg123
    pkg-config
    python3
  ];

  enableParallelBuilding = true;

  prePatch = magma.prePatch ./patches;

  preConfigure = ''
    ./autogen.sh
  '';

  configureFlags = [
    "--disable-shared"
    "--enable-ossfuzzers"
  ];

  buildFlags = [ "ossfuzz/sndfile_fuzzer" ];

  postInstall = ''
    cp ossfuzz/sndfile_fuzzer $out/bin
  '';

  passthru = {
    programs = [ "sndfile_fuzzer" ];
    args = { sndfile_fuzzer = "@@"; };
  };
}
