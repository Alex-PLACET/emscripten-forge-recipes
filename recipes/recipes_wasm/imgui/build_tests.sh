#!/bin/bash
set -euxo pipefail

emcmake cmake ${CMAKE_ARGS}       \
    -S tests                      \
    -B build_tests                \
    -GNinja                       \
    -DCMAKE_BUILD_TYPE=Release

emmake ninja -C build_tests

node build_tests/test_imgui.js
