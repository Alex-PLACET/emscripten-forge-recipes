#!/usr/bin/env bash
set -euo pipefail
export EMCC_CFLAGS="-O2 -g0 -fPIC -msimd128 -sSUPPORT_LONGJMP=wasm"
export CFLAGS="-I${PREFIX}/include"
export CXXFLAGS="-I${PREFIX}/include"
export LDFLAGS="-L${PREFIX}/lib"
mkdir -p build && cd build
emconfigure ../configure \
  --host=wasm32-unknown-emscripten \
  --prefix="${PREFIX}" \
  --enable-universal --enable-utf8 --disable-shared --disable-threads \
  --disable-xlocale --disable-richtext --disable-secretstore \
  --disable-detect_sm --disable-tests --without-subdirs \
  --with-libpng=sys --with-zlib=sys --with-expat=sys --with-libjpeg=sys \
  --without-libtiff --without-libcurl
emmake make -j"${CPU_COUNT:-2}"
emmake make install
mkdir -p "${PREFIX}/share/wx/wasm"
cp "${SRC_DIR}/build/wasm/wx.js" "${SRC_DIR}/build/wasm/template.html" "${PREFIX}/share/wx/wasm/"
