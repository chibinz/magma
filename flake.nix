{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.pkgs;
        llvmPkgs = pkgs.llvmPackages_14;
        stdenv = llvmPkgs.stdenv;
        fuzzers = import ./fuzzers;
        targets = import ./targets;
        deps = import ./deps.nix;
      in
      rec {
        packages = flake-utils.lib.flattenTree rec {
          afl = fuzzers.afl { inherit pkgs; };
          aflplusplus = fuzzers.aflplusplus { inherit pkgs; };
          llvm_lto = fuzzers.llvm_lto { inherit pkgs; };

          fuzzer = aflplusplus;

          libpng = targets.openssl {
            inherit (pkgs) fetchFromGitHub perl;
            inherit (fuzzer) stdenv driver;
          };
          default = libpng;
        };
      }
    );
}
