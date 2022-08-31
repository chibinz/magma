{ pkgs
, wrapClang
}:

let
  llvmPkgs = pkgs.llvmPackages_14;
  fuzzDepth = llvmPkgs.stdenv.mkDerivation {
    name = "FuzzDepth";
    src = /home/chibinzhang/FuzzDepth;

    buildInputs = [ llvmPkgs.llvm pkgs.meson pkgs.ninja ];
  };
in
fuzzDepth // {
  image = fuzzDepth;
  stdenv = pkgs.overrideCC pkgs.llvmPackages_14.stdenv (wrapClang {
    # inherit (fuzzDepth) cflags ldflags;
    llvmPkgs = pkgs.llvmPackages_14;
    cflags = [
      "-flto"
      "-g"
      "-Og"
      "-fpass-plugin=${fuzzDepth}/lib/libpass.so"
      "-fno-discard-value-names"
    ];
    ldflags = [
      "${fuzzDepth}/lib/libdriver.a"
      "${fuzzDepth}/lib/rt.o"
    ];
  });
  mkRunCommand = target: program: output: ''
    for p in ${target}/corpus/${program}/*; do
      ${target}/bin/${program} $p
    done
  '';
}
