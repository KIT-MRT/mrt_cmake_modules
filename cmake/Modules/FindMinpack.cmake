# - Find minpack
# Find the Minpack Library (minpack-dev in Xenial)
#
# Using libyaml-cpp:
#  find_package(Minpack REQUIRED)
#  include_directories(${MINPACK_INCLUDE_DIRS})
#  add_executable(foo foo.cc)
#  target_link_libraries(foo ${MINPACK_LIBRARIES})
# This module sets the following variables:
#  MINPACK_FOUND - set to true if the library is found
#  MINPACK_INCLUDE_DIRS - list of required include directories
#  MINPACK_LIBRARIES - list of libraries to be linked

find_package(PkgConfig)
#pkg_check_modules(MINPACK REQUIRED minpack)
find_path(MINPACK_INCLUDE_DIRECTORY
    NAMES minpack.h
    PATHS ${MINPACK_INCLUDE_DIRS} /usr/include
)
find_library(MINPACK_LIBRARY
    NAMES minpack
    PATHS /usr/lib)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(minpack 
    FOUND_VAR MINPACK_FOUND
    REQUIRED_VARS MINPACK_LIBRARY MINPACK_INCLUDE_DIRECTORY
)

if (MINPACK_FOUND)
    set(MINPACK_INCLUDE_DIRS ${MINPACK_INCLUDE_DIRECTORY})
    set(MINPACK_LIBRARIES ${MINPACK_LIBRARY})
endif ()
mark_as_advanced(MINPACK_INCLUDE_DIRECTORY MINPACK_LIBRARY)
