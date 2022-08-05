{ pkgs ? import <nixpkgs> { } }:

let
  llvmPkgs = pkgs.llvmPackages_9;
  clang = llvmPkgs.clang;

  # Copy pasted from
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/tools/security/afl/default.nix
  aflPostInstall = clang: cc: cxx: ''
    rm $out/bin/${cxx}
    cp $out/bin/${cc} $out/bin/${cxx}
    for c in $out/bin/${cc} $out/bin/${cxx}; do
      wrapProgram $c \
        --argv0 $c \
        --prefix AFL_PATH : $out/lib/afl \
        --run 'export AFL_CC=''${AFL_CC:-${clang}/bin/clang} AFL_CXX=''${AFL_CXX:-${clang}/bin/clang++}'
    done
  '';

  wrapCCExtraBuildCommand = cc: cxx: ''
    export named_cc=${cc};
    export named_cxx=${cxx};

    ln -s $ccPath/${cc} $out/bin/cc
    ln -s $ccPath/${cxx} $out/bin/c++
  '';

  afl = llvmPkgs.stdenv.mkDerivation rec {
    name = "afl";

    src = pkgs.fetchFromGitHub {
      owner = "google";
      repo = "AFL";
      rev = "master";
      hash = "sha256-PU6DRRreZbLCZ/sNtR37uHMHqhcOxm+whRLzNFQT7Tw=";
    };

    # AFL implicitly relies on which to check for `llvm-config` availability.
    buildInputs = [ llvmPkgs.llvm pkgs.which pkgs.makeWrapper ];

    makeFlags = [ "AFL_NO_X86=1" "PREFIX=$(out)" ];

    postBuild = ''
      make -C llvm_mode -j $NIX_BUILD_CORES
    '';

    postInstall = aflPostInstall clang "afl-clang-fast" "afl-clang-fast++" + ''
      c++ -c -std=c++11 -o $out/lib/afl/afl_driver.o ${./src/afl_driver.cpp}
      ar -r $out/lib/afl/libafl_driver.a $out/lib/afl/afl_driver.o
    '';
  };
in
afl // {
  inherit aflPostInstall wrapCCExtraBuildCommand;
  driver = "${afl}/lib/afl/libafl_driver.a";
  stdenv = pkgs.overrideCC llvmPkgs.stdenv (pkgs.wrapCCWith {
    cc = afl;
    extraBuildCommands = wrapCCExtraBuildCommand "afl-clang-fast" "afl-clang-fast++";
  });
}
