# - Find libyaml-cpp
# Find the YAML C++ Library
#
# Using libyaml-cpp:
#  find_package(yaml-cpp REQUIRED)
#  include_directories(${yaml-cpp_INCLUDE_DIRS})
#  add_executable(foo foo.cc)
#  target_link_libraries(foo ${yaml-cpp_LIBRARIES})
# This module sets the following variables:
#  yaml-cpp_FOUND - set to true if the library is found
#  yaml-cpp_INCLUDE_DIRS - list of required include directories
#  yaml-cpp_LIBRARIES - list of libraries to be linked

find_package(PkgConfig REQUIRED)
pkg_check_modules(YAML-CPP REQUIRED yaml-cpp)
find_path(YAML-CPP_INCLUDE_DIRECTORY
    NAMES yaml.h
    PATHS ${YAML-CPP_INCLUDE_DIRS} /usr/include/yaml-cpp
)
find_library(YAML-CPP_LIBRARY
    NAMES yaml-cpp
    PATHS ${YAML-CPP_LIBRARY_DIRS})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(yaml-cpp 
    FOUND_VAR yaml-cpp_FOUND
    REQUIRED_VARS YAML-CPP_LIBRARY YAML-CPP_INCLUDE_DIRECTORY
)

if (yaml-cpp_FOUND)
    set(yaml-cpp_INCLUDE_DIRS ${YAML-CPP_INCLUDE_DIRECTORY})
    set(yaml-cpp_LIBRARIES ${YAML-CPP_LIBRARY})
endif ()
mark_as_advanced(YAML-CPP_INCLUDE_DIRECTORY YAML-CPP_LIBRARY)
