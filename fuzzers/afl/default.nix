{ magma
, pkgs
, aflPostInstall
, wrapCCExtraBuildCommand
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
  release_version = "9.0.1";
in
afl // {
  stdenv = pkgs.overrideCC llvmPkgs.stdenv (pkgs.wrapCCWith rec {
    cc = afl;
    isClang = true;
    extraBuildCommands = ''
      export named_cc=afl-clang-fast
      export named_cxx=afl-clang-fast++

      wrap $named_cc $wrapper $ccPath/$named_cc
      wrap $named_cxx $wrapper $ccPath/$named_cxx

      rsrc="$out/resource-root"
      mkdir "$rsrc"
      ln -s "${llvmPkgs.clang-unwrapped.lib}/lib/clang/${release_version}/include" "$rsrc"
      echo "-resource-dir=$rsrc" >> $out/nix-support/cc-cflags

      ln -s $out/bin/afl-clang-fast $out/bin/cc
      ln -s $out/bin/afl-clang-fast++ $out/bin/c++
    '';
    # wrapCCExtraBuildCommand "afl-clang-fast" "afl-clang-fast++";
    nixSupport = {
      cc-cflags = magma.cflags;
      cc-ldflags = magma.ldflags ++ [ "${afl}/lib/afl/libafl_driver.a" "-lstdc++" ];
    };
  });
}
