{
  cmake,
  fetchFromGitHub,
  lib,
  libjpeg,
  libmodplug,
  libogg,
  libpng,
  libtheora,
  libvorbis,
  libwebp,
  lua5_1,
  mesa,
  mpg123,
  openal,
  pkg-config,
  physfs,
  SDL2,
  stdenv,
  xorg,
  zlib,
}:

stdenv.mkDerivation rec {
  pname = "love";
  version = "11.5";

  src = fetchFromGitHub {
    owner = "love2d";
    repo = "love";
    rev = version;
    hash = "sha256-sem36AKK79EC2oeV/RS5ikWxU8P93clz0xtK1PKwkME=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    zlib
    libpng
    libjpeg
    libwebp
    freetype
    physfs
    openal
    SDL2
    libvorbis
    libogg
    libtheora
    libmodplug
    mpg123
    lua5_1
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    mesa
    xorg.libX11
  ];

  cmakeFlags = [
    (lib.cmakeBool "LIBLOVE_USE_SYSTEM_ZLIB" true)
    (lib.cmakeBool "LIBLOVE_USE_SYSTEM_LIBPNG" true)
    (lib.cmakeBool "LIBLOVE_USE_SYSTEM_LIBJPEG" true)
    (lib.cmakeBool "LIBLOVE_USE_SYSTEM_WEBP" true)
    (lib.cmakeBool "LIBLOVE_USE_SYSTEM_FREETYPE" true)
    (lib.cmakeBool "LIBLOVE_USE_SYSTEM_PHYSFS" true)
    (lib.cmakeBool "LIBLOVE_USE_SYSTEM_OPENAL" true)
    (lib.cmakeBool "LIBLOVE_USE_SYSTEM_SDL2" true)
    (lib.cmakeBool "LIBLOVE_USE_SYSTEM_OGG" true)
    (lib.cmakeBool "LIBLOVE_USE_SYSTEM_VORBIS" true)
    (lib.cmakeBool "LIBLOVE_USE_SYSTEM_THEORA" true)
    (lib.cmakeBool "LIBLOVE_USE_SYSTEM_MODPLUG" true)
    (lib.cmakeBool "LIBLOVE_USE_SYSTEM_MPG123" true)
    # Lua 5.1 (Darwin lib name differs from Linux)
    "-DLUA_INCLUDE_DIR=${lua5_1.out}/include"
    "-DLUA_LIBRARIES=${
      if stdenv.hostPlatform.isDarwin then
        "${lua5_1.out}/lib/liblua.5.1.dylib"
      else
        "${lua5_1.out}/lib/liblua5.1.so"
    }"
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    "-DCMAKE_OSX_DEPLOYMENT_TARGET=10.13"
    # Make the installed binary find @rpath/*.dylib in $out/lib
    "-DCMAKE_MACOSX_RPATH=ON"
    "-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON"
  ]
  ++ [
    "-DCMAKE_INSTALL_RPATH=${placeholder "out"}/lib"
  ];

  # Ensure common macOS frameworks are linked.
  NIX_LDFLAGS = lib.optionalString stdenv.hostPlatform.isDarwin "-framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo";

  # Upstream lacks install rules; install manually from the build dir.
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/lib"
    # binary
    install -m755 love "$out/bin/love"
    # shared lib: install all dylib files found
    install -m755 lib*.dylib "$out/lib/" 2>/dev/null || true
    runHook postInstall
  '';

  # On Darwin, make sure install_name IDs and rpaths are sane at runtime.
  postFixup = lib.optionalString stdenv.hostPlatform.isDarwin ''
    # Give the dylib an @rpath id so dependents resolve it via the binary's rpath
    install_name_tool -id "@rpath/libliblove.dylib" "$out/lib/libliblove.dylib" 2>/dev/null || true
    # Ensure the executable has an rpath to ../lib (redundant with CMake flags but safe)
    install_name_tool -add_rpath "@loader_path/../lib" "$out/bin/love" 2>/dev/null || true
  '';

  meta = {
    description = "Framework for making 2D games in Lua";
    homepage = "https://love2d.org/";
    license = lib.licenses.zlib;
    platforms = lib.platforms.unix;
    mainProgram = "love";
    maintainers = with lib.maintainers; [
      raskin
      dannydannydanny
    ];
  };
}
