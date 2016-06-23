#compiler flags
include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG("-std=c++14" Cpp14CompilerFlag)
if (${Cpp14CompilerFlag})
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS "17")
	#no additional flag is required
else()
	message(FATAL_ERROR "Compiler does not have c++14 support. Use at least g++4.9 or Visual Studio 2013 and newer.")
endif()

#change RelWithDepInfo fomr O2 to O3 for c and c++
macro(replace_opt_compiler_flag CMAKE_VARIABLE_NAME)
	set(${CMAKE_VARIABLE_NAME}_NEW "${${CMAKE_VARIABLE_NAME}}")
	#replace gcc opt flag
	string(REPLACE -O2 -O3 ${CMAKE_VARIABLE_NAME}_NEW "${${CMAKE_VARIABLE_NAME}_NEW}")
	#replace MSVC opt flag
	string(REPLACE /Ob1 /Ob2 ${CMAKE_VARIABLE_NAME}_NEW "${${CMAKE_VARIABLE_NAME}_NEW}")
	
	set(${CMAKE_VARIABLE_NAME} "${${CMAKE_VARIABLE_NAME}_NEW}" CACHE STRING "Flags used by the compiler during release builds with debug information." FORCE)
endmacro()

replace_opt_compiler_flag(CMAKE_C_FLAGS_RELWITHDEBINFO)
replace_opt_compiler_flag(CMAKE_CXX_FLAGS_RELWITHDEBINFO)

#add OpenMP
find_package(OpenMP REQUIRED)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")

#add diagnostics color
CHECK_CXX_COMPILER_FLAG("-fdiagnostics-color=auto" DiagColorCompilerFlag)
if (${DiagColorCompilerFlag})
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fdiagnostics-color=auto")
endif()

