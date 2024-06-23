cmake_minimum_required (VERSION 3.22)
message("CMake Version: ${CMAKE_VERSION}")

project (Gauntlet)

add_compile_definitions (GAME_PATH="${CMAKE_CURRENT_SOURCE_DIR}/game")
add_subdirectory (extern)