{ magma
, stdenv
, driver
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
        ${./src}/$f.cc $out/lib/libxml2.a ${driver} -lz -llzma
    done
  '';
}
/*
  #!/bin/bash

  apt-get
  update && \
  apt-get install - y git make autoconf automake libtool pkg-config zlib1g-dev \
  liblzma-dev
  #!/bin/bash

  ##
  # Pre-requirements:
  # - env TARGET: path to target work dir
  ##

  git
  clone - -no-checkout https://gitlab.gnome.org/GNOME/libxml2.git \
  "$TARGET/repo"
  git - C "$TARGET/repo" checkout ec6e3efb06d7b15cf5a2328fabd3845acea4c815
  #!/bin/bash
  set - e

  ##
  # Pre-requirements:
  # - env TARGET: path to target work dir
  # - env OUT: path to directory where artifacts are stored
  # - env CC, CXX, FLAGS, LIBS, etc...
  ##

  if [ ! -d "$TARGET/repo" ]; then
  echo "fetch.sh must be executed first."
  exit 1
  fi

  cd "$TARGET/repo"
  ./autogen.sh \
  --with-http=no \
  --with-python=no \
  --with-lzma=yes \
  --with-threads=no \
  --disable-shared
  make -j$(nproc) clean
  make -j$(nproc) all
*/
