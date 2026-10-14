#!/bin/bash
set -euo pipefail

export CFLAGS="${CFLAGS:-} ${EMCC_CFLAGS:-} -Wno-pass-failed"
export CXXFLAGS="${CXXFLAGS:-} ${EMCC_CFLAGS:-} -Wno-pass-failed"

emcmake cmake -S cmake -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -Donnxruntime_BUILD_WEBASSEMBLY=ON \
    -Donnxruntime_BUILD_WEBASSEMBLY_STATIC_LIB=ON \
    -Donnxruntime_ENABLE_WEBASSEMBLY_SIMD=ON \
    -Donnxruntime_ENABLE_WEBASSEMBLY_THREADS=OFF \
    -Donnxruntime_USE_WEBGPU=ON \
    -Donnxruntime_USE_WEBNN=OFF \
    -Donnxruntime_DISABLE_WASM_EXCEPTION_CATCHING=ON \
    -Donnxruntime_BUILD_UNIT_TESTS=OFF \
    -Donnxruntime_BUILD_BENCHMARKS=OFF \
    -Donnxruntime_USE_FULL_PROTOBUF=OFF \
    -Donnxruntime_WGSL_TEMPLATE=static \
    -Donnxruntime_ENABLE_PYTHON=ON \
    -DPython_EXECUTABLE="${PYTHON}" \
    -DPython_INCLUDE_DIR="${PREFIX}/include/python${PY_VER}" \
    -DPython_NumPy_INCLUDE_DIR="${PREFIX}/lib/python${PY_VER}/site-packages/numpy/_core/include" \
    -DCMAKE_PROJECT_INCLUDE="${RECIPE_DIR}/overwriteProp.cmake" \
    -DCMAKE_SHARED_LINKER_FLAGS="${EM_FORGE_SIDE_MODULE_LDFLAGS} -fwasm-exceptions -sSUPPORT_LONGJMP=wasm" \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DFETCHCONTENT_QUIET=OFF

emmake ninja -C build -j"${CPU_COUNT}"

# cd build
# ninja install

#Install static library
mkdir -p "${PREFIX}/lib"
cp build/libonnxruntime_webassembly.a "${PREFIX}/lib/"

# ---------------------------------------------------------------------------
# Install the Python package tree (onnxruntime/ + onnxruntime/capi/)
# ---------------------------------------------------------------------------
PY_VER="${PY_VER:?PY_VER not set by cross-python activation}"
SP="${PREFIX}/lib/python${PY_VER}/site-packages"
ORT_PY="${SRC_DIR}/onnxruntime/python"

mkdir -p "${SP}/onnxruntime/capi" "${SP}/onnxruntime/backend"

cp "${SRC_DIR}/onnxruntime/"*.py "${SP}/onnxruntime/"
cp "${SRC_DIR}/onnxruntime/py.typed" "${SP}/onnxruntime/"
cp "${SRC_DIR}/LICENSE" "${SP}/onnxruntime/"
cp "${SRC_DIR}/ThirdPartyNotices.txt" "${SP}/onnxruntime/"
cp "${SRC_DIR}/docs/Privacy.md" "${SP}/onnxruntime/"
cp "${ORT_PY}/"*.py "${SP}/onnxruntime/capi/"
cp "${ORT_PY}/backend/"*.py "${SP}/onnxruntime/backend/"

sed -e 's/@ONNXRUNTIME_IMPORT_PYTORCH_TO_RESOLVE_DLLS@//' \
    -e 's/@ONNXRUNTIME_SETDLOPENFLAGS_GLOBAL@//' \
    -e 's/@ONNXRUNTIME_SETDLOPENFLAGS_LOCAL@//' \
    "${ORT_PY}/_pybind_state.py.in" > "${SP}/onnxruntime/capi/_pybind_state.py"

MODULE_SO="build/onnxruntime/capi/onnxruntime_pybind11_state.so"
if [ ! -f "${MODULE_SO}" ]; then
    MODULE_SO="$(find build -name 'onnxruntime_pybind11_state.so' -print -quit)"
fi
if [ -z "${MODULE_SO}" ] || [ ! -f "${MODULE_SO}" ]; then
    echo "ERROR: onnxruntime_pybind11_state.so not found in build tree" >&2
    exit 1
fi

EXT_SUFFIX="$("${PYTHON}" -c 'import sysconfig; print(sysconfig.get_config_var("EXT_SUFFIX") or ".so")')"
cp "${MODULE_SO}" "${SP}/onnxruntime/capi/onnxruntime_pybind11_state${EXT_SUFFIX}"

# build_and_package_info.py is written by ORT's setup.py, not by CMake.
# Use the version from the source tree: with a staging output rattler-build does
# not export PKG_VERSION, and VERSION_NUMBER is authoritative for the release.
ORT_VERSION="$(tr -d '[:space:]' < "${SRC_DIR}/VERSION_NUMBER")"
cat > "${SP}/onnxruntime/capi/build_and_package_info.py" <<EOF
package_name = 'onnxruntime'
__version__ = '${ORT_VERSION}'
EOF

rm -rf "${SP}/onnxruntime/__pycache__" "${SP}/onnxruntime/capi/__pycache__"

echo "✅ onnxruntime Python package installed ✅"

echo "✅ onnxruntime build complete ✅"

mkdir -p "${PREFIX}/include/onnxruntime"

cp -r include/onnxruntime/. "${PREFIX}/include/onnxruntime/"

echo "✅ onnxruntime headers installed ✅"

# Install the vendored emdawnwebgpu package used by the WebGPU provider so
# downstream consumers can link the same runtime glue expected by ORT.
EMDAWN_SRC_ROOT="build/_deps/dawn-src"
EMDAWN_GEN_ROOT="build/_deps/dawn-build/gen/src/emdawnwebgpu"
EMDAWN_PREFIX="${PREFIX}/share/emdawnwebgpu"

mkdir -p "${EMDAWN_PREFIX}/webgpu/src"
mkdir -p "${EMDAWN_PREFIX}/webgpu/include/webgpu"
mkdir -p "${EMDAWN_PREFIX}/webgpu/include/dawn"
mkdir -p "${EMDAWN_PREFIX}/webgpu_cpp/include/webgpu"
mkdir -p "${EMDAWN_PREFIX}/webgpu_cpp/include/dawn"

cp "${EMDAWN_SRC_ROOT}/src/emdawnwebgpu/pkg/emdawnwebgpu.port.py" "${EMDAWN_PREFIX}/"
cp "${EMDAWN_SRC_ROOT}/src/emdawnwebgpu/pkg/README.md" "${EMDAWN_PREFIX}/"
cp "${EMDAWN_SRC_ROOT}/third_party/emdawnwebgpu/pkg/webgpu/src/webgpu.cpp" "${EMDAWN_PREFIX}/webgpu/src/"
cp "${EMDAWN_SRC_ROOT}/third_party/emdawnwebgpu/pkg/webgpu/src/library_webgpu.js" "${EMDAWN_PREFIX}/webgpu/src/"
cp "${EMDAWN_SRC_ROOT}/third_party/emdawnwebgpu/pkg/webgpu/src/webgpu-externs.js" "${EMDAWN_PREFIX}/webgpu/src/"
cp "${EMDAWN_SRC_ROOT}/third_party/emdawnwebgpu/pkg/webgpu/src/LICENSE" "${EMDAWN_PREFIX}/webgpu/src/"
cp "${EMDAWN_GEN_ROOT}/library_webgpu_enum_tables.js" "${EMDAWN_PREFIX}/webgpu/src/"
cp "${EMDAWN_GEN_ROOT}/library_webgpu_generated_sig_info.js" "${EMDAWN_PREFIX}/webgpu/src/"
cp "${EMDAWN_GEN_ROOT}/library_webgpu_generated_struct_info.js" "${EMDAWN_PREFIX}/webgpu/src/"
cp "${EMDAWN_GEN_ROOT}/include/webgpu/"* "${EMDAWN_PREFIX}/webgpu/include/webgpu/"
cp "${EMDAWN_GEN_ROOT}/include/dawn/webgpu_cpp_print.h" "${EMDAWN_PREFIX}/webgpu/include/dawn/"
cp "${EMDAWN_GEN_ROOT}/include/webgpu/webgpu_cpp.h" "${EMDAWN_PREFIX}/webgpu_cpp/include/webgpu/"
cp "${EMDAWN_GEN_ROOT}/include/webgpu/webgpu_cpp_chained_struct.h" "${EMDAWN_PREFIX}/webgpu_cpp/include/webgpu/"
cp "${EMDAWN_GEN_ROOT}/include/webgpu/webgpu_enum_class_bitmasks.h" "${EMDAWN_PREFIX}/webgpu_cpp/include/webgpu/"
cp "${EMDAWN_GEN_ROOT}/include/webgpu/webgpu_glfw.h" "${EMDAWN_PREFIX}/webgpu_cpp/include/webgpu/"
cp "${EMDAWN_GEN_ROOT}/include/dawn/webgpu_cpp_print.h" "${EMDAWN_PREFIX}/webgpu_cpp/include/dawn/"

echo "✅ emdawnwebgpu package installed ✅"

mkdir -p "${PREFIX}/lib/cmake/onnxruntime"
sed "s/@VERSION@/${ORT_VERSION}/g" \
    "${RECIPE_DIR}/onnxruntimeConfig.cmake" \
    > "${PREFIX}/lib/cmake/onnxruntime/onnxruntimeConfig.cmake"

echo "✅ onnxruntime CMake config installed ✅"
