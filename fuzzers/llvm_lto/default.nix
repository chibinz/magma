{ magma
, pkgs
, dummyDriver
, wrapClang
}:

let
  llvmPkgs = pkgs.llvmPackages_14;

  clang-lto = wrapClang {
    inherit llvmPkgs;
    cflags = [ "-flto" ];
    ldflags = [ dummyDriver.driver "-lstdc++" ];
  };
in
{
  stdenv = pkgs.overrideCC llvmPkgs.stdenv clang-lto;
}
