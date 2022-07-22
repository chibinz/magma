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
        deps = import ./deps.nix { inherit pkgs llvmPkgs stdenv; };
      in
      rec {
        packages = flake-utils.lib.flattenTree rec {
          libpng = import ./targets/libpng { inherit pkgs llvmPkgs stdenv deps; };
          default = libpng;
        };
      }
    );
}
