with import <nixpkgs> { };

stdenv.mkDerivation rec {
  name = "json";

  src = pkgs.fetchFromGitHub {
    owner = "nlohmann";
    repo = "json";
    rev = "v3.10.5";
    hash = "sha256-DTsZrdB9GcaNkx7ZKxcgCA3A9ShM5icSF0xyGguJNbk=";
  };

  buildInputs = [ which ];

  installPhase = ''
    mkdir -p $out/bin
    c++ -I $src/single_include -o $out/bin/fuzzer-parse_json \
      $src/test/src/fuzzer-parse_json.cpp
  '';
}
