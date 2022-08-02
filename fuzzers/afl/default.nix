{ pkgs ? import <nixpkgs> {} }:

let
  llvmPkgs = pkgs.llvmPackages_9;
  stdenv = llvmPkgs.stdenv;
  clang = llvmPkgs.clang;
  afl = stdenv.mkDerivation rec {
    name = "afl";

    src = pkgs.fetchFromGitHub {
      owner = "google";
      repo = "AFL";
      rev = "master";
      hash = "sha256-PU6DRRreZbLCZ/sNtR37uHMHqhcOxm+whRLzNFQT7Tw=";
    };

    # AFL implicitly relies on which to check for `llvm-config` availability.
    buildInputs = [ llvmPkgs.llvm pkgs.which pkgs.makeWrapper ];

    installFlags = [ "PREFIX=$(out)" ];
    postBuild = ''
      make -C llvm_mode -j $NIX_BUILD_CORES
    '';

    # Copy pasted from
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/tools/security/afl/default.nix
    postInstall = ''
      rm $out/bin/afl-clang-fast++
      cp $out/bin/afl-clang-fast $out/bin/afl-clang-fast++
      for x in $out/bin/afl-clang-fast $out/bin/afl-clang-fast++; do
        wrapProgram $x \
          --prefix AFL_PATH : "$out/lib/afl" \
          --run 'export AFL_CC=''${AFL_CC:-${clang}/bin/clang} AFL_CXX=''${AFL_CXX:-${clang}/bin/clang++}'
      done
    '';
  };
in
afl // {
  cc = "${afl}/bin/afl-clang-fast";
  cxx = "${afl}/bin/afl-clang-fast++";
  lib = ./src/afl_driver.cpp;
  inherit stdenv;
}
