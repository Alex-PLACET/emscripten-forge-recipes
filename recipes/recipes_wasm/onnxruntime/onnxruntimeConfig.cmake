# onnxruntimeConfig.cmake
# CMake configuration file for onnxruntime (static WebAssembly build)
#
# Usage in consumer CMakeLists.txt:
#
#   find_package(onnxruntime REQUIRED)
#   target_link_libraries(my_target PRIVATE onnxruntime::onnxruntime)
#
# This will automatically bring in the include directories and the Emscripten
# link options needed to build a working binary.

cmake_minimum_required(VERSION 3.20)

# Compute the installation prefix from this file's location.
# Assumes this file is installed at:
#   <prefix>/lib/cmake/onnxruntime/onnxruntimeConfig.cmake
get_filename_component(_ORT_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_ORT_IMPORT_PREFIX "${_ORT_IMPORT_PREFIX}" PATH)
get_filename_component(_ORT_IMPORT_PREFIX "${_ORT_IMPORT_PREFIX}" PATH)
get_filename_component(_ORT_IMPORT_PREFIX "${_ORT_IMPORT_PREFIX}" PATH)

set(_ORT_LIB "${_ORT_IMPORT_PREFIX}/lib/libonnxruntime_webassembly.a")
set(_ORT_INCLUDE_DIR "${_ORT_IMPORT_PREFIX}/include")
set(_ORT_EMDAWNWEBGPU_PORT "${_ORT_IMPORT_PREFIX}/share/emdawnwebgpu/emdawnwebgpu.port.py")

# Verify the library is present
if(NOT EXISTS "${_ORT_LIB}")
    set(onnxruntime_FOUND FALSE)
    if(onnxruntime_FIND_REQUIRED)
        message(FATAL_ERROR "onnxruntime: library not found at ${_ORT_LIB}")
    elseif(NOT onnxruntime_FIND_QUIETLY)
        message(WARNING "onnxruntime: library not found at ${_ORT_LIB}")
    endif()
    return()
endif()

# Create the IMPORTED target
if(NOT TARGET onnxruntime::onnxruntime)
    add_library(onnxruntime::onnxruntime STATIC IMPORTED)

    set_target_properties(onnxruntime::onnxruntime PROPERTIES
        IMPORTED_LOCATION "${_ORT_LIB}"
        INTERFACE_INCLUDE_DIRECTORIES "${_ORT_INCLUDE_DIR}"
    )

    # Emscripten link options required when producing a standalone binary.
    # Consumers that build shared-side-modules or Python extensions may need to
    # override / remove these according to their own linker requirements.
    if(EMSCRIPTEN)
        set(_ORT_WEBGPU_LINK_OPTION -sUSE_WEBGPU=1)
        if(EXISTS "${_ORT_EMDAWNWEBGPU_PORT}")
            set(_ORT_WEBGPU_LINK_OPTION "--use-port=${_ORT_EMDAWNWEBGPU_PORT}")
        elseif(DEFINED EMSCRIPTEN_VERSION AND EMSCRIPTEN_VERSION VERSION_GREATER_EQUAL "4.0.10")
            set(_ORT_WEBGPU_LINK_OPTION --use-port=emdawnwebgpu)
        endif()

        set_property(TARGET onnxruntime::onnxruntime APPEND PROPERTY
            INTERFACE_LINK_OPTIONS
                -msimd128
                ${_ORT_WEBGPU_LINK_OPTION}
                -sALLOW_MEMORY_GROWTH=1
                -sINITIAL_MEMORY=64MB
                -sEXIT_RUNTIME=1
        )
    endif()
endif()

# Version information
set(onnxruntime_VERSION "@VERSION@")
set(ONNXRUNTIME_VERSION "@VERSION@")

# Convenience / legacy variables
set(onnxruntime_FOUND TRUE)
set(ONNXRUNTIME_FOUND TRUE)
set(ONNXRUNTIME_INCLUDE_DIRS "${_ORT_INCLUDE_DIR}")
set(ONNXRUNTIME_LIBRARIES    "${_ORT_LIB}")

# Cleanup
unset(_ORT_IMPORT_PREFIX)
unset(_ORT_LIB)
unset(_ORT_INCLUDE_DIR)
unset(_ORT_EMDAWNWEBGPU_PORT)
unset(_ORT_WEBGPU_LINK_OPTION)
