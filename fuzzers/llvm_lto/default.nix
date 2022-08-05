{ pkgs
, dummyDriver
}:

let
  llvmPkgs = pkgs.llvmPackages_14;
  release_version = "14.0.1";
  mkExtraBuildCommands = cc: ''
    rsrc="$out/resource-root"
    mkdir "$rsrc"
    ln -s "${cc.lib}/lib/clang/${release_version}/include" "$rsrc"
    echo "-resource-dir=$rsrc" >> $out/nix-support/cc-cflags

    ln -s "${llvmPkgs.compiler-rt.out}/lib" "$rsrc/lib"
    ln -s "${llvmPkgs.compiler-rt.out}/share" "$rsrc/share"
  '';

  clang-lto = pkgs.wrapCCWith rec {
    cc = llvmPkgs.clang-unwrapped;
    libcxx = llvmPkgs.libcxx;
    bintools = llvmPkgs.bintools;
    extraPackages = [
      llvmPkgs.libcxxabi
      llvmPkgs.compiler-rt
    ];
    extraBuildCommands = mkExtraBuildCommands cc;
    nixSupport = {
      cc-cflags = [ "-flto" ];
    };
  };
in
{
  stdenv = pkgs.overrideCC llvmPkgs.stdenv clang-lto;
  driver = dummyDriver.driver;
}
