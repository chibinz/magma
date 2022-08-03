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
      with pkgs;
      rec {
        packages = flake-utils.lib.flattenTree rec {
          afl = fuzzers.afl { inherit pkgs; };
          llvm_lto = fuzzers.llvm_lto { inherit pkgs; };
          libpng = targets.libpng {
            inherit fetchFromGitHub zlib;
            driver = llvm_lto.driver;
            stdenv = llvm_lto.stdenv;
          };
          default = libpng;
        };
      }
    );
}
