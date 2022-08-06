{ stdenv
, driver
, autoconf
, autoreconfHook
, bison
, fetchFromGitHub
, icu
, pkg-config
, re2c
}:

with import <nixpkgs> { };

let
  oniguruma = stdenv.mkDerivation rec {
    pname = "onig";
    version = "6.9.7.1";

    src = fetchFromGitHub {
      owner = "kkos";
      repo = "oniguruma";
      rev = "227ec0bd690207812793c09ad70024707c405376";
      sha256 = "sha256-iYbfxFI3QlKwKEmDOz5CGcgm1MV3+0QeZnZSl4cPnO0=";
    };

    buildInputs = [ autoreconfHook ];

    enableParallelBuilding = true;

    configureFlags = [ "--disable-shared" ];
  };

in

stdenv.mkDerivation
{
  name = "php";

  src = fetchFromGitHub {
    owner = "php";
    repo = "php-src";
    rev = "ad04345eb34992f8f3f0ee310664e1848f3346b1";
    hash = "sha256-HUo8xTLYa8tBDcKACyjdhyy8+A8CBpHaTZ1ffULaez8=";
  };

  buildInputs = [ oniguruma autoconf bison icu pkg-config re2c ];

  enableParallelBuilding = true;

  patches = [ ./patches/setup/setup.patch ];

  # PHP's zend_function union is incompatible with the object-size sanitizer
  EXTRA_CFLAGS = "-fno-sanitize=object-size";
  EXTRA_CXXFLAGS = "-fno-sanitize=object-size";
  LIB_FUZZING_ENGINE = driver;

  preConfigure = ''
    ./buildconf
  '';

  configureFlags = [
    "--disable-shared"
    "--disable-all"
    "--disable-cgi"
    "--disable-phpdbg"
    "--enable-option-checking=fatal"
    "--enable-fuzzer"
    "--enable-exif"
    "--enable-phar"
    "--enable-intl"
    "--enable-mbstring"
    "--with-pic"
    "--without-pcre-jit"
  ];

  postConfigure = ''
    substituteInPlace Makefile \
      --replace "-rpath /ORIGIN/lib" ""
  '';

  programs = [
    "json"
    "exif"
    "unserialize"
    "parser"
  ];
}
