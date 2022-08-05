{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.pkgs;
        fuzzers = [
          "afl"
          "aflplusplus"
          "llvm_lto"
        ];
        targets = [
          "libpng"
          "lua"
          "openssl"
          "sqlite3"
        ];
        buildSingleHelper = { f, t }:
          let
            fuzzer = pkgs.callPackage  ./fuzzers/${f} { };
            target = pkgs.callPackage ./targets/${t} {
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
          default = buildAll;
        };
      }
    );
}
