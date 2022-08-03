{ pkgs ? import <nixpkgs> { } }:

let
  llvmPkgs = pkgs.llvmPackages_14;
  clang = llvmPkgs.clang;
  aflplusplus = llvmPkgs.stdenv.mkDerivation {
    version = "4.01c";
    pname = "aflplusplus";

    src = pkgs.fetchFromGitHub {
      owner = "AFLplusplus";
      repo = "AFLplusplus";
      rev = "4.01c";
      hash = "sha256-V4X1VG2oeg1Avpg1lr2bw+m6z+46hjN4mQFwhk6ZShY=";
    };

    buildInputs = [ llvmPkgs.llvm llvmPkgs.lld pkgs.makeWrapper ];

    makeFlags = [ "AFL_NO_X86=1" "PREFIX=$(out)" ];

    preInstall = ''
      sed -i 's/-$(LLVM_BINDIR)//g' utils/aflpp_driver/GNUmakefile
    '';

    postInstall = ''
      rm $out/bin/afl-c++
      cp $out/bin/afl-cc $out/bin/afl-c++
      for x in $out/bin/afl-cc $out/bin/afl-c++; do
        wrapProgram $x \
          --argv0 "$x" \
          --prefix AFL_PATH : "$out/lib/afl" \
          --run 'export AFL_CC=''${AFL_CC:-${clang}/bin/clang} AFL_CXX=''${AFL_CXX:-${clang}/bin/clang++}'
      done
    '';
  };
  afl-cc = pkgs.wrapCCWith {
    cc = aflplusplus;
    extraBuildCommands = ''
      export named_cc=afl-cc
      export named_cxx=afl-c++

      ln -s $ccPath/afl-cc $out/bin/cc
      ln -s $ccPath/afl-c++ $out/bin/c++
    '';
  };
in
aflplusplus // {
  driver = "${aflplusplus}/lib/afl/libAFLDriver.a";
  stdenv = pkgs.overrideCC llvmPkgs.stdenv afl-cc;
}
