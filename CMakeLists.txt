cmake_minimum_required (VERSION 3.22)

project (Gauntlet)

add_subdirectory (extern)

set (SRCS
	"src/application.cpp"

	"src/framework/components/custom_cmp.cpp"
	"src/framework/systems/custom_sys.cpp"
)

if (BX_BUILD_EDITOR)
	set (SRCS ${SRCS}
		"src/editor/inspector.cpp"
)
endif ()

include_directories (${CMAKE_CURRENT_SOURCE_DIR}/include)

add_executable (${PROJECT_NAME} ${SRCS})
target_link_libraries (${PROJECT_NAME} bx)

if (BX_INSTALL)
	install(TARGETS ${PROJECT_NAME} DESTINATION bin)
endif ()