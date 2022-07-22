{ pkgs
, llvmPkgs
, stdenv
}:

{
  zlib = stdenv.mkDerivation rec {
    pname = "zlib";
    version = "v1.2.12";

    src = pkgs.fetchFromGitHub {
      owner = "madler";
      repo = pname;
      rev = version;
      hash = "sha256-bIm5+uHv12/x2uqEbZ4/VGzUJnDzW9C3GkyHo3EnC1A=";
    };

    buildInputs = [ llvmPkgs.lld ];
    dontDisableStatic = true;
    configureFlags = [ "--static" ];

    preConfigure = ''
      export CFLAGS="$CFLAGS -flto -fuse-ld=lld"
    '';
  };
}
