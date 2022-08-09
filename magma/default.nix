with import <nixpkgs> { };

stdenv.mkDerivation rec {
  name = "magma";

  buildInputs = [ daemontools ];

  src = ./src;

  magmaStorage = "/magma_shared/canaries.raw";

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
}
