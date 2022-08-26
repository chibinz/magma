{ pkgs
, aflPostInstall
, wrapClang
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

    enableParallelBuilding = true;

    makeFlags = [ "AFL_NO_X86=1" "PREFIX=$(out)" ];

    preInstall = ''
      substituteInPlace utils/aflpp_driver/GNUmakefile \
        --replace '-$(LLVM_BINDIR)' ""
    '';

    postInstall = aflPostInstall clang "afl-cc" "afl-c++";
  };
in
aflplusplus // rec {
  driver = "${aflplusplus}/lib/afl/libAFLDriver.a";
  stdenv = pkgs.overrideCC llvmPkgs.stdenv (wrapClang {
    inherit llvmPkgs;
    cc = aflplusplus;
    cc_name = "afl-cc";
    cxx_name = "afl-c++";
    ldflags = [ driver "-lstdc++" ];
  });
  image = pkgs.runCommand "aflplusplus-image" {} ''
    mkdir -p $out/bin

    len=$(echo -n ${aflplusplus} | wc -c)
    rep=$(printf '/%.0s' $(seq 1 $len))
    sed "s|${aflplusplus}|$rep|g" ${aflplusplus}/bin/afl-fuzz > $out/bin/afl-fuzz
    chmod +x $out/bin/afl-fuzz
  '';
  mkRunCommand = target: program: output: ''
    ${aflplusplus}/bin/afl-fuzz -i ${target}/corpus/${program} -o ${output} -- ${target}/bin/${program}
  '';
}
