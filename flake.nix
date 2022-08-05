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
          "sqlite3"
        ];
        buildSingle = { f, t }:
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
        buildBench = name: fs: ts:
          let
            buildSet = pkgs.lib.attrsets.cartesianProductOfSets { f = fs; t = ts; };
            BuildList = map buildSingle buildSet;
          in
          pkgs.linkFarm name BuildList;
        buildSingleTarget = f: t: (buildSingle { inherit f t; }).path;
        buildAll = buildBench "magma" fuzzers targets;
      in
      rec {
        packages = flake-utils.lib.flattenTree rec {
          default = buildAll;
        };
      }
    );
}
