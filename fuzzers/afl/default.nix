{ pkgs ? import <nixpkgs> {} }:

let
  llvmPkgs = pkgs.llvmPackages_9;
  stdenv = llvmPkgs.stdenv;
  afl = stdenv.mkDerivation rec {
    name = "afl";

    src = pkgs.fetchFromGitHub {
      owner = "google";
      repo = "AFL";
      rev = "master";
      hash = "sha256-PU6DRRreZbLCZ/sNtR37uHMHqhcOxm+whRLzNFQT7Tw=";
    };

    # AFL implicitly relies on which to check for `llvm-config` availability.
    buildInputs = [ llvmPkgs.llvm pkgs.which ];

    installFlags = [ "PREFIX=$(out)" ];
    postBuild = ''
      make -C llvm_mode -j $NIX_BUILD_CORES
    '';
  };
in
afl // {
  cc = "${afl}/bin/afl-clang-fast";
  cxx = "${afl}/bin/afl-clang-fast++";
  lib = ./src/afl_driver.cpp;
  envConfigure = ''
    export AFL_PATH=${afl}/lib/afl
  '';
  inherit stdenv;
}
