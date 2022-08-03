{ pkgs ? import <nixpkgs> {} }:

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

    postBuild = ''
      make -C llvm_mode -j $NIX_BUILD_CORES
    '';

    installFlags = [ "PREFIX=$(out)" ];

    driver = ./src/afl_driver.cpp;

    # Copy pasted from
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/tools/security/afl/default.nix
    postInstall = ''
      rm $out/bin/afl-clang-fast++
      cp $out/bin/afl-clang-fast $out/bin/afl-clang-fast++
      for x in $out/bin/afl-clang-fast $out/bin/afl-clang-fast++; do
        wrapProgram $x \
          --argv0 "$x" \
          --prefix AFL_PATH : "$out/lib/afl" \
          --run 'export AFL_CC=''${AFL_CC:-${clang}/bin/clang} AFL_CXX=''${AFL_CXX:-${clang}/bin/clang++}'
      done

      c++ -c -std=c++11 -o $out/lib/afl/afl_driver.o ${driver}
    '';

  };
  afl-cc = pkgs.wrapCCWith {
    cc = afl;
    extraBuildCommands = ''
      # Don't wrap afl-clang-fast, since it already references a wrapped clang
      export named_cc=afl-clang-fast
      export named_cxx=afl-clang-fast++

      # Create symlinks
      ln -s $ccPath/afl-clang-fast $out/bin/cc
      ln -s $ccPath/afl-clang-fast++ $out/bin/c++
    '';
  };
in
afl // {
  driver = "${afl}/lib/afl/afl_driver.o";
  stdenv = pkgs.overrideCC llvmPkgs.stdenv afl-cc;
}
