{ stdenv
, daemontools
, isan ? false
, harden ? false
, canaries ? false
, fixes ? false
, magmaShared ? "/magma_shared"
, magmaStorage ? "${magmaShared}/canaries.raw"
}:

let
  magma = stdenv.mkDerivation rec {
    name = "magma";

    buildInputs = [ daemontools ];

    src = ./src;

    CFLAGS = builtins.concatStringsSep " " [
      "-g"
      "-fPIC"
      "-DMAGMA_STORAGE=\"${magmaStorage}\""
    ];

    buildPhase = ''
      cc $CFLAGS -c canary.c -o canary.o;
      cc $CFLAGS -c monitor.c -o monitor.o;
      cc $CFLAGS -c storage.c -o storage.o;

      ar -r libmagma.a canary.o storage.o;
      cc monitor.o storage.o -o monitor;
    '';

    installPhase = ''
      mkdir -p $out/bin $out/lib $out/include

      cp monitor ${./run.sh} ${./runonce.sh} $out/bin
      cp libmagma.a $out/lib
      cp -r arch/ canary.h common.h storage.h $out/include
    '';
  };
  isanFlag = if isan then " -DMAGMA_FATAL_CANARIES" else "";
  hardenFlag = if harden then " -DMAGMA_HARDEN_CANARIES" else "";
  canariesFlag = if canaries then " -DMAGMA_ENABLE_CANARIES" else "";
  fixesFlag = if fixes then " -DMAGMA_ENABLE_FIXES" else "";
in
magma // {
  cflags = [
    "-include"
    "${magma}/include/canary.h"
    isanFlag
    hardenFlag
    canariesFlag
    fixesFlag
  ];
  ldflags = [
    "${magma}/lib/libmagma.a"
    "-lrt"
  ];
  prePatch = dir: ''
    for p in $(find ${dir}/setup ${dir}/bugs -name '*.patch'); do
        name=$(basename $p .patch)
        sed "s/%MAGMA_BUG%/$name/g" $p > /tmp/$name.patch
        patches="$patches /tmp/$name.patch"
     done
  '';
}
