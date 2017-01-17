include(CheckCXXCompilerFlag)

#Require C++14
if (CMAKE_VERSION VERSION_LESS "3.1")
  CHECK_CXX_COMPILER_FLAG("-std=c++14" Cpp14CompilerFlag)
  if (${Cpp14CompilerFlag})
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
    set(CMAKE_CXX_STANDARD 14)
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS "17")
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    #no additional flag is required
  else()
    message(FATAL_ERROR "Compiler does not have c++14 support. Use at least g++4.9 or Visual Studio 2013 and newer.")
  endif()
else ()
  set (CMAKE_CXX_STANDARD 14)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif ()

#add OpenMP
find_package(OpenMP REQUIRED)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")

# add gcov flags
if(MRT_ENABLE_COVERAGE)
    include(MRTCoverage)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g --coverage")
    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g --coverage")
endif()

#add diagnostics color
CHECK_CXX_COMPILER_FLAG("-fdiagnostics-color=auto" DiagColorCompilerFlag)
if (${DiagColorCompilerFlag})
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fdiagnostics-color=auto")
endif()

