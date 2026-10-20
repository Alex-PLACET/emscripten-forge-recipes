cmake_minimum_required(VERSION 3.16)
project(test_imgui CXX)

find_package(imgui CONFIG REQUIRED)

add_executable(test_imgui main.cpp)
target_link_libraries(
    test_imgui
    PRIVATE
        imgui::imgui
        imgui::imgui_impl_null
)
