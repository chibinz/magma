{ magma
, stdenv
, driver
, fetchFromGitHub
, cairo
, cmake
, boost
, freetype
, libjpeg
, libpng
, libtiff
, openjpeg
, pkg-config
, zlib
}:

stdenv.mkDerivation {
  name = "poppler";

  src = fetchFromGitHub {
    owner = "freedesktop";
    repo = "poppler";
    rev = "1d23101ccebe14261c6afc024ea14f29d209e760";
    hash = "sha256-qkh+88PwXmaQCRVDuBYzruznWi2QQ/6F5sL+FHxVbXg=";
  };

  buildInputs = [
    cairo
    cmake
    boost
    freetype
    libjpeg
    libpng
    libtiff
    openjpeg
    pkg-config
    zlib
  ];

  enableParallelBuilding = true;

  prePatch = magma.prePatch ./patches;

  cmakeFlags = [
    # "-DCMAKE_BUILD_TYPE=debug"
    "-DBUILD_SHARED_LIBS=OFF"
    "-DBUILD_GTK_TESTS=OFF"
    "-DBUILD_QT5_TESTS=OFF"
    "-DBUILD_CPP_TESTS=OFF"
    "-DENABLE_LIBPNG=ON"
    "-DENABLE_LIBTIFF=ON"
    "-DENABLE_LIBJPEG=ON"
    "-DENABLE_SPLASH=ON"
    "-DENABLE_UTILS=ON"
    "-DENABLE_CMS=none"
    "-DENABLE_LIBCURL=OFF"
    "-DENABLE_GLIB=OFF"
    "-DENABLE_GOBJECT_INTROSPECTION=OFF"
    "-DENABLE_QT5=OFF"
    "-DENABLE_LIBCURL=OFF"
    "-DWITH_Cairo=ON"
    "-DWITH_NSS3=OFF"
    "-DFONT_CONFIGURATION=generic"
    # "-DFREETYPE_INCLUDE_DIRS=$WORK/include/freetype2"
    # "-DFREETYPE_LIBRARY=$WORK/lib/libfreetype.a"
    # "-DICONV_LIBRARIES=/usr/lib/x86_64-linux-gnu/libc.so"
    # "-DCMAKE_EXE_LINKER_FLAGS_INIT=$LIBS"
  ];

  postInstall = ''
    c++ -std=c++11 -I $out/include/poppler/cpp -o $out/bin/pdf_fuzzer \
    ${./src/pdf_fuzzer.cc} $out/lib/libpoppler-cpp.a $out/lib/libpoppler.a \
    ${driver} -lfreetype -ljpeg -lz -lopenjp2 -lpng -ltiff -lm
  '';

  passthru = {
    programs = [ "pdf_fuzzer" "pdfimages" "pdftoppm" ];
    args = { pdfimages = "@@ /tmp/out"; pdftoppm = "-mono -cropbox @@"; };
  };
}
