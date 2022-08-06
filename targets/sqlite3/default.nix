{ fetchFromGitHub
, stdenv
, driver
, tcl
}:

stdenv.mkDerivation rec {
  name = "sqlite";

  src = fetchFromGitHub {
    owner = "sqlite";
    repo = "sqlite";
    rev = "version-3.37.0";
    hash = "sha256-w4K/gbFfFSKMF78NJOMa12/WGIv6ymSNYU8KztG1bow=";
  };

  buildInputs = [ tcl ];

  enableParallelBuilding = true;

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

  programs = [ "sqlite3_fuzz" ];

  buildFlags = [ "sqlite3.o" ];

  postInstall = ''
    cc -c -I $out/include -o ossfuzz.o test/ossfuzz.c
    c++ -pthread -o $out/bin/${builtins.head programs} \
      ossfuzz.o $out/lib/libsqlite3.a ${driver} -ldl -lm
  '';
}
