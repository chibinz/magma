{ pkgs
, aflPostInstall
, wrapClang
}:

let
  llvmPkgs = pkgs.llvmPackages_9;
  clang = llvmPkgs.clang;

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

    enableParallelBuilding = true;

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
afl // rec {
  driver = "${afl}/lib/afl/libafl_driver.a";
  stdenv = pkgs.overrideCC llvmPkgs.stdenv (wrapClang {
    inherit llvmPkgs;
    cc = afl;
    cc_name = "afl-clang-fast";
    cxx_name = "afl-clang-fast++";
    ldflags = [ driver "-lstdc++" ];
  });
}
