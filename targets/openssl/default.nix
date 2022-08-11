{ magma
, stdenv
, fetchFromGitHub
, perl
}:

stdenv.mkDerivation rec {
  name = "openssl";

  src = fetchFromGitHub {
    owner = "openssl";
    repo = "openssl";
    rev = "3bd5319b5d0df9ecf05c8baba2c401ad8e3ba130";
    hash = "sha256-JAcAxUGWRQbfMQWUW2H6vaoQ2TOHqV/Fnoy029wUSmM=";
  };

  buildInputs = [ perl ];

  enableParallelBuilding = true;

  prePatch = magma.prePatch ./patches + ''
    cp ${./src/abilist.txt} abilist.txt;
  '';

  configFlags = [
    "--prefix=$out"
    "--debug"
    "no-asm"
    "no-module"
    "no-shared"
    "no-threads"
    "disable-tests"
    "enable-tls1_3"
    "enable-rc5"
    "enable-md2"
    "enable-ec_nistp_64_gcc_128"
    "enable-ssl3"
    "enable-ssl3-method"
    "enable-nextprotoneg"
    "enable-weak-ssl-ciphers"
    "-DPEDANTIC"
    "-DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"
    "-fno-sanitize=alignment"

    "enable-fuzz-libfuzzer"
  ];

  configurePhase = ''
    perl Configure ${builtins.concatStringsSep " " configFlags}
  '';

  programs = [
    "asn1"
    "asn1parse"
    "bignum"
    "bndiv"
    "client"
    "cmp"
    "cms"
    "conf"
    "crl"
    "ct"
    "server"
    "x509"
  ];

  postInstall = ''
    for p in ${builtins.concatStringsSep " " programs}; do
        cp fuzz/$p $out/bin/$p
    done;
  '';
}
