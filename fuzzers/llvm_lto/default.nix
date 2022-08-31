{ pkgs
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
dummyDriver // {
  image = dummyDriver;
  stdenv = pkgs.overrideCC llvmPkgs.stdenv clang-lto;
  mkRunCommand = target: program: output: ''
    for p in ${target}/corpus/${program}/*; do
      ${target}/bin/${program} $p
    done
  '';
}
