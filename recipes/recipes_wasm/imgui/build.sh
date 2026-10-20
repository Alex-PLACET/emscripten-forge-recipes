#!/bin/bash
set -euxo pipefail

mkdir -p build
cd build

cmake ${CMAKE_ARGS} ${SRC_DIR}           \
    -GNinja                              \
    -DCMAKE_BUILD_TYPE=Release           \
    -DCMAKE_INSTALL_LIBDIR=lib           \
    -DCMAKE_INSTALL_PREFIX=${PREFIX}     \
    -DIMGUI_VERSION=${PKG_VERSION}

ninja install
