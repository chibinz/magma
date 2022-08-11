{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.pkgs;
        magma = pkgs.callPackage ./magma { canaries = true; };
        fuzzers = [
          "afl"
          # "aflplusplus"
          "llvm_lto"
        ];
        targets = [
          "libpng"
          "libsndfile"
          "libtiff"
          "libxml2"
          "lua"
          "openssl"
          "php"
          "poppler"
          "sqlite3"
        ];
        dummyDriver = (pkgs.runCommandCC "dummy-driver" { } ''
          mkdir -p $out/lib
          cc -c -o driver.o ${./driver.c}
          ar -r $out/lib/libdriver.a driver.o
        '') // { driver = "${dummyDriver}/lib/libdriver.a"; };
        wrapCCNameHelper = cc_name: cxx_name: ''
          if test ! -e $out/bin/cc -a ! -e $out/bin/c++; then
            export named_cc=${cc_name}
            export named_cxx=${cxx_name}

            wrap $named_cc $wrapper $ccPath/$named_cc
            wrap $named_cxx $wrapper $ccPath/$named_cxx

            ln -s $out/bin/$named_cc $out/bin/cc
            ln -s $out/bin/$named_cxx $out/bin/c++
          fi
        '';
        aflPostInstall = clang: cc: cxx: ''
          # Modified from
          # https://github.com/NixOS/nixpkgs/blob/master/pkgs/tools/security/afl/default.nix
          rm $out/bin/${cxx}
          cp $out/bin/${cc} $out/bin/${cxx}
          for c in $out/bin/${cc} $out/bin/${cxx}; do
            wrapProgram $c \
              --argv0 $c \
              --prefix AFL_PATH : $out/lib/afl \
              --prefix AFL_CC : ${clang}/bin/clang \
              --prefix AFL_CXX : ${clang}/bin/clang++
          done
        '';
        mkExtraBuildCommands = llvmPkgs: ''
          rsrc="$out/resource-root"
          mkdir "$rsrc"
          ln -s "${llvmPkgs.clang-unwrapped.lib}/lib/clang/${llvmPkgs.release_version}/include" "$rsrc"
          echo "-resource-dir=$rsrc" >> $out/nix-support/cc-cflags

          ln -s "${llvmPkgs.compiler-rt.out}/lib" "$rsrc/lib"
          ln -s "${llvmPkgs.compiler-rt.out}/share" "$rsrc/share"
        '';
        wrapClang =
          { llvmPkgs
          , cc ? llvmPkgs.clang-unwrapped
          , bintools ? llvmPkgs.bintools
          , cc_name ? "clang"
          , cxx_name ? "clang++"
          , cflags ? [ ]
          , ldflags ? [ ]
          , ...
          } @ args:
          pkgs.wrapCCWith
            rec {
              inherit cc bintools;
              isClang = true;
              extraPackages = [
                # compiler-rt is needed for sanitizers
                llvmPkgs.compiler-rt
              ];
              extraBuildCommands =
                (wrapCCNameHelper cc_name cxx_name) + mkExtraBuildCommands llvmPkgs;
              nixSupport = {
                cc-cflags = magma.cflags ++ cflags;
                cc-ldflags = magma.ldflags ++ ldflags;
              };
            } // args;
        callPackage = pkgs.lib.callPackageWith (pkgs // {
          inherit magma dummyDriver wrapClang aflPostInstall;
        });
        buildSingleHelper = { f, t }:
          let
            fuzzer = callPackage  ./fuzzers/${f} { };
            target = callPackage ./targets/${t} {
              inherit (fuzzer) stdenv;
            };
          in
          {
            name = "${f}-${t}";
            path = target;
          };
        buildSingle = f: t: (buildSingleHelper { inherit f t; }).path;
        buildMultiple = name: fs: ts:
          let
            buildSet = pkgs.lib.attrsets.cartesianProductOfSets { f = fs; t = ts; };
            BuildList = map buildSingleHelper buildSet;
          in
          pkgs.linkFarm name BuildList;
        buildAll = buildMultiple "magma" fuzzers targets;
      in
      rec {
        packages = flake-utils.lib.flattenTree rec {
          default = buildSingle "llvm_lto" "libpng";
        };
      }
    );
}
