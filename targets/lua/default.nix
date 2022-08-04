{ fetchFromGitHub
, stdenv
, driver
, readline
}:

stdenv.mkDerivation {
  name = "lua";

  src = fetchFromGitHub {
    owner = "lua";
    repo = "lua";
    rev = "dbdc74dc5502c2e05e1c1e2ac894943f418c8431";
    hash = "sha256-OPCTULiACQAU6XrzH0knXYsqRAz3ZHr5w79hSZ0wxfg=";
  };

  patches = [ ./patches/setup/lua.patch ];

  buildInputs = [ readline ];

  installPhase = ''
    mkdir -p $out/bin $out/lib
    cp liblua.a $out/lib
    cp lua $out/bin
  '';
}
