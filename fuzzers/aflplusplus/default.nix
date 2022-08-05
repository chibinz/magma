{ pkgs
, aflPostInstall
, wrapCCExtraBuildCommand
}:

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
      substituteInPlace utils/aflpp_driver/GNUmakefile \
        --replace '-$(LLVM_BINDIR)' ""
    '';

    postInstall = aflPostInstall clang "afl-cc" "afl-c++";
  };
in
aflplusplus // {
  driver = "${aflplusplus}/lib/afl/libAFLDriver.a";
  stdenv = pkgs.overrideCC llvmPkgs.stdenv (pkgs.wrapCCWith rec {
    cc = aflplusplus;
    libcxx = llvmPkgs.libcxx;
    bintools = llvmPkgs.bintools;
    extraBuildCommands = wrapCCExtraBuildCommand "afl-cc" "afl-c++";
  });
}
