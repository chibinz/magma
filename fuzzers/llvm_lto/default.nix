{ pkgs ? import <nixpkgs> { } }:

let
  llvmPkgs = pkgs.llvmPackages_14;
  release_version = "14.0.1";
  mkExtraBuildCommands0 = cc: ''
    rsrc="$out/resource-root"
    mkdir "$rsrc"
    ln -s "${cc.lib}/lib/clang/${release_version}/include" "$rsrc"
    echo "-resource-dir=$rsrc" >> $out/nix-support/cc-cflags
  '';
  mkExtraBuildCommands = cc: mkExtraBuildCommands0 cc + ''
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
  stdenv = pkgs.overrideCC llvmPkgs.stdenv clang-lto;
  dummy = stdenv.mkDerivation {
    name = "dummy-driver";
    src = ./.;

    buildPhase = ''
      mkdir -p $out/lib
      cc -c -o $out/lib/driver.o $src/driver.c
      ar -r $out/lib/libdriver.a $out/lib/driver.o
    '';

    dontInstall = true;
  };
in
{
  inherit stdenv;
  driver = "${dummy}/lib/driver.o";
}
