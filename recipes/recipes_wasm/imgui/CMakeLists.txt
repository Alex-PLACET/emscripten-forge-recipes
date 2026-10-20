cmake_minimum_required(VERSION 3.16)

if(NOT DEFINED IMGUI_VERSION)
    set(IMGUI_VERSION "0.0.0")
endif()

project(imgui VERSION ${IMGUI_VERSION} LANGUAGES CXX)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# Core library: imgui + std::string helpers.
add_library(imgui
    imgui.cpp
    imgui_demo.cpp
    imgui_draw.cpp
    imgui_tables.cpp
    imgui_widgets.cpp
    misc/cpp/imgui_stdlib.cpp
)
add_library(imgui::imgui ALIAS imgui)

target_include_directories(
    imgui
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)
target_compile_features(imgui PUBLIC cxx_std_11)
set_target_properties(imgui PROPERTIES POSITION_INDEPENDENT_CODE ON)

# Optional platform/renderer backends. They are kept as separate static
# libraries so consumers only pull in the platform dependencies they use.
function(imgui_add_backend target source)
    add_library(${target} ${source})
    target_link_libraries(${target} PUBLIC imgui)
    target_compile_features(${target} PUBLIC cxx_std_11)
    set_target_properties(${target} PROPERTIES POSITION_INDEPENDENT_CODE ON)
endfunction()

imgui_add_backend(imgui_impl_null backends/imgui_impl_null.cpp)

imgui_add_backend(imgui_impl_glfw backends/imgui_impl_glfw.cpp)
if(EMSCRIPTEN)
    # Emscripten ships GLFW 3.2; users preferring contrib.glfw3 can remove
    # these interface options in their own build.
    target_compile_options(imgui_impl_glfw INTERFACE "-sUSE_GLFW=3")
    target_link_options(imgui_impl_glfw INTERFACE "-sUSE_GLFW=3")
endif()

imgui_add_backend(imgui_impl_sdl2 backends/imgui_impl_sdl2.cpp)
target_compile_options(imgui_impl_sdl2 PRIVATE "-sUSE_SDL=2")
if(EMSCRIPTEN)
    target_compile_options(imgui_impl_sdl2 INTERFACE "-sUSE_SDL=2")
    target_link_options(imgui_impl_sdl2 INTERFACE "-sUSE_SDL=2")
endif()

imgui_add_backend(imgui_impl_sdlrenderer2 backends/imgui_impl_sdlrenderer2.cpp)
target_compile_options(imgui_impl_sdlrenderer2 PRIVATE "-sUSE_SDL=2")
if(EMSCRIPTEN)
    target_compile_options(imgui_impl_sdlrenderer2 INTERFACE "-sUSE_SDL=2")
    target_link_options(imgui_impl_sdlrenderer2 INTERFACE "-sUSE_SDL=2")
endif()

# On Emscripten this backend defaults to OpenGL ES 2 (WebGL), which also
# works with WebGL 2 contexts. Sources are installed for custom configurations.
imgui_add_backend(imgui_impl_opengl3 backends/imgui_impl_opengl3.cpp)

install(
    TARGETS
        imgui
        imgui_impl_null
        imgui_impl_glfw
        imgui_impl_sdl2
        imgui_impl_sdlrenderer2
        imgui_impl_opengl3
    EXPORT imgui-targets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(
    FILES
        imgui.h
        imgui_internal.h
        imconfig.h
        imstb_rectpack.h
        imstb_textedit.h
        imstb_truetype.h
        misc/cpp/imgui_stdlib.h
        backends/imgui_impl_null.h
        backends/imgui_impl_glfw.h
        backends/imgui_impl_sdl2.h
        backends/imgui_impl_sdlrenderer2.h
        backends/imgui_impl_opengl3.h
        backends/imgui_impl_opengl3_loader.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# Ship the backend implementation files so downstream projects can compile
# them with a custom configuration (e.g. OpenGL ES 3 or contrib.glfw3).
install(
    FILES
        backends/imgui_impl_null.cpp
        backends/imgui_impl_glfw.cpp
        backends/imgui_impl_sdl2.cpp
        backends/imgui_impl_sdlrenderer2.cpp
        backends/imgui_impl_opengl3.cpp
    DESTINATION ${CMAKE_INSTALL_DATADIR}/imgui/backends
)

configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/imgui-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/imgui-config.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/imgui
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/imgui-config-version.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(
    FILES
        ${CMAKE_CURRENT_BINARY_DIR}/imgui-config.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/imgui-config-version.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/imgui
)

install(
    EXPORT imgui-targets
    NAMESPACE imgui::
    FILE imgui-targets.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/imgui
)
