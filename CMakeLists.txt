cmake_minimum_required (VERSION 3.22)

project (Gauntlet)

add_subdirectory (extern)

set (SRCS
	# Custom files here
)

add_executable (${PROJECT_NAME} ${SRCS})
target_link_libraries (${PROJECT_NAME} bx)
install(TARGETS ${PROJECT_NAME} DESTINATION bin)