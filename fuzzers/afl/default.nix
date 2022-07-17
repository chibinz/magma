{ pkgs
,
}:

let
  llvmPkgs = pkgs.llvmPackages_9;
  stdenv = llvmPkgs.stdenv;
in
stdenv.mkDerivation rec {
  name = "afl";

  src = pkgs.fetchFromGitHub
    {
      owner = "google";
      repo = "AFL";
      rev = "master";
      hash = "sha256-PU6DRRreZbLCZ/sNtR37uHMHqhcOxm+whRLzNFQT7Tw=";
    };

  # AFL implicitly relies on which to check for `llvm-config` availability.
  buildInputs = [ llvmPkgs.llvm pkgs.which ];

  postBuild = ''
    make -C llvm_mode -j $NIX_BUILD_CORES
  '';

  installFlags = [ "PREFIX=$(out)" ];

  inherit stdenv;
}
