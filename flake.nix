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
          "aflplusplus"
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
        aflPostInstall = clang: cc: cxx: ''
          # Copy pasted from
          # https://github.com/NixOS/nixpkgs/blob/master/pkgs/tools/security/afl/default.nix
          rm $out/bin/${cxx}
          cp $out/bin/${cc} $out/bin/${cxx}
          for c in $out/bin/${cc} $out/bin/${cxx}; do
            wrapProgram $c \
              --argv0 $c \
              --prefix AFL_PATH : $out/lib/afl \
              --run 'export AFL_CC=''${AFL_CC:-${clang}/bin/clang} AFL_CXX=''${AFL_CXX:-${clang}/bin/clang++}'
          done
        '';
        wrapCCExtraBuildCommand = cc: cxx: ''
          export named_cc=${cc};
          export named_cxx=${cxx};

          ln -s $ccPath/${cc} $out/bin/cc
          ln -s $ccPath/${cxx} $out/bin/c++
        '';
        callPackage = pkgs.lib.callPackageWith (pkgs // {
          inherit magma aflPostInstall dummyDriver wrapCCExtraBuildCommand;
        });
        buildSingleHelper = { f, t }:
          let
            fuzzer = callPackage  ./fuzzers/${f} { };
            target = callPackage ./targets/${t} {
              inherit (fuzzer) stdenv driver;
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
