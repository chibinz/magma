{ magma
, pkgs
, wrapClang
}:

# with import <nixpkgs> {};
let
  llvmPkgs = pkgs.llvmPackages_11;
  libfuzzer = pkgs.stdenv.mkDerivation {
    name = "libfuzzer";

    src = pkgs.fetchFromGitHub {
      owner = "llvm";
      repo = "llvm-project";
      rev = "29cc50e17a6800ca75cd23ed85ae1ddf3e3dcc14";
      hash = "sha256-Ek+Y7j4kyFPyKQDHwyiOqulQYR9/XwKZ+1b7bfSb/mQ=";
    };

    buildInputs = [ llvmPkgs.llvm ];

    buildPhase = ''
      cd compiler-rt/lib/fuzzer

      ls *.cpp | xargs -n 1 -P $NIX_BUILD_CORES \
        c++ -c -O2 -fpic -std=c++11
    '';

    installPhase = ''
      mkdir -p $out/lib
      ar -r $out/lib/libfuzzer.a *.o
      c++ -c -fpic -std=c++11 -o $out/lib/driver.o ${./src/driver.cpp}
    '';
  };
in
libfuzzer // {
  stdenv = pkgs.overrideCC llvmPkgs.stdenv (wrapClang {
    inherit llvmPkgs;
    cflags = [ "-fsanitize=fuzzer-no-link" ];
    ldflags = [ "${libfuzzer}/lib/driver.o" "${libfuzzer}/lib/libfuzzer.a" "-lstdc++" ];
  });
}
/*
  #!/bin/bash
  set -e

  apt-get update && \
  apt-get install -y make build-essential wget git

  apt-get install -y apt-utils apt-transport-https ca-certificates gnupg

  echo deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-11 main >> /etc/apt/sources.list
  wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -

  apt-get update && \
  apt-get install -y clang-11

  update-alternatives \
  --install /usr/lib/llvm              llvm             /usr/lib/llvm-11  20 \
  --slave   /usr/bin/llvm-config       llvm-config      /usr/bin/llvm-config-11  \
  --slave   /usr/bin/llvm-ar           llvm-ar          /usr/bin/llvm-ar-11 \
  --slave   /usr/bin/llvm-as           llvm-as          /usr/bin/llvm-as-11 \
  --slave   /usr/bin/llvm-bcanalyzer   llvm-bcanalyzer  /usr/bin/llvm-bcanalyzer-11 \
  --slave   /usr/bin/llvm-c-test       llvm-c-test      /usr/bin/llvm-c-test-11 \
  --slave   /usr/bin/llvm-cov          llvm-cov         /usr/bin/llvm-cov-11 \
  --slave   /usr/bin/llvm-diff         llvm-diff        /usr/bin/llvm-diff-11 \
  --slave   /usr/bin/llvm-dis          llvm-dis         /usr/bin/llvm-dis-11 \
  --slave   /usr/bin/llvm-dwarfdump    llvm-dwarfdump   /usr/bin/llvm-dwarfdump-11 \
  --slave   /usr/bin/llvm-extract      llvm-extract     /usr/bin/llvm-extract-11 \
  --slave   /usr/bin/llvm-link         llvm-link        /usr/bin/llvm-link-11 \
  --slave   /usr/bin/llvm-mc           llvm-mc          /usr/bin/llvm-mc-11 \
  --slave   /usr/bin/llvm-nm           llvm-nm          /usr/bin/llvm-nm-11 \
  --slave   /usr/bin/llvm-objdump      llvm-objdump     /usr/bin/llvm-objdump-11 \
  --slave   /usr/bin/llvm-ranlib       llvm-ranlib      /usr/bin/llvm-ranlib-11 \
  --slave   /usr/bin/llvm-readobj      llvm-readobj     /usr/bin/llvm-readobj-11 \
  --slave   /usr/bin/llvm-rtdyld       llvm-rtdyld      /usr/bin/llvm-rtdyld-11 \
  --slave   /usr/bin/llvm-size         llvm-size        /usr/bin/llvm-size-11 \
  --slave   /usr/bin/llvm-stress       llvm-stress      /usr/bin/llvm-stress-11 \
  --slave   /usr/bin/llvm-symbolizer   llvm-symbolizer  /usr/bin/llvm-symbolizer-11 \
  --slave   /usr/bin/llvm-tblgen       llvm-tblgen      /usr/bin/llvm-tblgen-11

  update-alternatives \
  --install /usr/bin/clang                 clang                  /usr/bin/clang-11     20 \
  --slave   /usr/bin/clang++               clang++                /usr/bin/clang++-11 \
  --slave   /usr/bin/clang-cpp             clang-cpp              /usr/bin/clang-cpp-11
  #!/bin/bash
  set -e

  ##
  # Pre-requirements:
  # - env FUZZER: path to fuzzer work dir
  ##

  git clone --no-checkout https://github.com/llvm/llvm-project.git "$FUZZER/repo"
  git -C "$FUZZER/repo" checkout 29cc50e17a6800ca75cd23ed85ae1ddf3e3dcc14#!/bin/bash
  set -e

  ##
  # Pre-requirements:
  # - env FUZZER: path to fuzzer work dir
  ##

  # We need the version of LLVM which has the LLVMFuzzerRunDriver exposed
  cd "$FUZZER/repo/compiler-rt/lib/fuzzer"
  for f in *.cpp; do
  	clang++ -stdlib=libstdc++ -fPIC -O2 -std=c++11 $f -c &
  done && wait
  ar r "$OUT/libFuzzer.a" *.o

  clang++ $CXXFLAGS -std=c++11 -c "$FUZZER/src/driver.cpp" -fPIC -o "$OUT/driver.o"
*/
