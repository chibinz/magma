{ magma
, stdenv
, fetchzip
, tcl
}:

stdenv.mkDerivation rec {
  name = "sqlite";

  src = fetchzip {
    url = "https://www.sqlite.org/src/tarball/sqlite.tar.gz?r=8c432642572c8c4b";
    hash = "sha256-M2jTP7pPAl8FCBYj+fMCptR8yuC6nixvScN5Ahs5oxQ=";
  };

  buildInputs = [ tcl ];

  enableParallelBuilding = true;

  prePatch = magma.prePatch ./patches;

  configureFlags = [
    "--disable-shared"
    "--disable-tcl"
    "--enable-rtree"
  ];

  CFLAGS = builtins.concatStringsSep " " [
    "-DSQLITE_DEBUG=1"
    "-DSQLITE_MAX_LENGTH=128000000"
    "-DSQLITE_MAX_SQL_LENGTH=128000000"
    "-DSQLITE_MAX_MEMORY=25000000"
    "-DSQLITE_MAX_PAGE_COUNT=16384"
    "-DSQLITE_PRINTF_PRECISION_LIMIT=1048576"
  ];

  buildFlags = [ "sqlite3.o" ];

  postInstall = ''
    cp -r ${./corpus} $out/corpus

    cc -c -I $out/include -o ossfuzz.o test/ossfuzz.c
    c++ -pthread -o $out/bin/${builtins.head programs} \
      ossfuzz.o $out/lib/libsqlite3.a -ldl -lm
  '';

  passthru.programs = [ "sqlite3_fuzz" ];
}
