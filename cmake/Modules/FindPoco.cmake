# CMake find script for Poco C++ library
# Adapted from: https://github.com/astahl/poco-cmake/blob/master/cmake/FindPoco.cmake
#
# The following components are available:
# ---------------------------------------
# Util (loaded by default)
# Foundation (loaded by default)
# XML
# Zip
# Crypto
# Data
# Net
# NetSSL_OpenSSL
# OSP
#
# Usage:
#	find_package(Poco REQUIRED OSP Data Crypto) 
#
# On completion, the script defines the following variables:
#	
#	- Compound variables:
#   Poco_FOUND 
#		- true if all requested components were found.
#	Poco_LIBRARIES 
#		- contains release (and debug if available) libraries for all requested components.
#		  It has the form "optimized LIB1 debug LIBd1 optimized LIB2 ...", ready for use with the target_link_libraries command.
#	Poco_INCLUDE_DIRS
#		- Contains include directories for all requested components.

find_path(Poco_INCLUDE_DIRS NAMES Poco/Poco.h PATHS /usr/include)

# append the default minimum components to the list to find
list(APPEND components 
  ${Poco_FIND_COMPONENTS} 
  Util
  Foundation
)
list(REMOVE_DUPLICATES components)

set(search_for_debug false)
if (${CMAKE_BUILD_TYPE} MATCHES [d|D][e|E][b|B][u|U][g|G])
  set(search_for_debug true)
endif ()

set(Poco_LIBRARIES "")
set(Poco_LIBRARY_VAR_NAMES "")
# iterate the components
foreach(component ${components})
	# release library
    if (${search_for_debug})
        find_library(Poco_${component}_library NAMES Poco${component}d PATHS /usr/lib)
    else()
        find_library(Poco_${component}_library NAMES Poco${component} PATHS /usr/lib)
    endif()
    list(APPEND Poco_LIBRARIES ${Poco_${component}_library})
    list(APPEND Poco_LIBRARY_VAR_NAMES Poco_${component}_library)
endforeach()

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(Poco FOUND_VAR Poco_FOUND REQUIRED_VARS Poco_INCLUDE_DIRS ${POCO_LIBRARY_VAR_NAMES})
mark_as_advanced(${Poco_LIBRARY_VAR_NAMES})


