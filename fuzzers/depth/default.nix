{ pkgs
, wrapClang
}:

let
  llvmPkgs = pkgs.llvmPackages_git;
  fuzzDepth = llvmPkgs.stdenv.mkDerivation {
    name = "FuzzDepth";
    src = /home/chibinzhang/FuzzDepth;

    buildInputs = [ llvmPkgs.llvm pkgs.meson pkgs.ninja ];
  };
in
fuzzDepth // {
  image = fuzzDepth;
  stdenv = pkgs.overrideCC llvmPkgs.stdenv (wrapClang {
    inherit llvmPkgs;
    cflags = [
      "-flto"
      "-g"
      "-Og"
      "-fpass-plugin=${fuzzDepth}/lib/libpass.so"
      "-fno-discard-value-names"
    ];
    ldflags = [
      "--load-pass-plugin=${fuzzDepth}/lib/libpass.so"
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
