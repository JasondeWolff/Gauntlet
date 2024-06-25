cmake_minimum_required (VERSION 3.22)
message(STATUS "CMake Version: ${CMAKE_VERSION}")
message(STATUS "C++ Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "C++ Compiler Version: ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "C Compiler Version: ${CMAKE_C_COMPILER_VERSION}")

project (Gauntlet)

add_compile_definitions (GAME_PATH="${CMAKE_CURRENT_SOURCE_DIR}/game")
add_subdirectory (extern)

set (SRCS
	# Custom files here
)

add_executable (${PROJECT_NAME} ${SRCS})
target_link_libraries (${PROJECT_NAME} bx)