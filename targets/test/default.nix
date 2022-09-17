{ magma
, stdenv
}:

stdenv.mkDerivation {
  name = "test";

  src = ./.;

  buildPhase = ''
    cc -o fuzz fuzz.c
    cc -o hello hello.c
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp fuzz hello $out/bin
  '';

  passthru.programs = [ "fuzz" ];
}
