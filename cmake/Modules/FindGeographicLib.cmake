# Look for GeographicLib
#
# Set
#  GEOGRAPHICLIB_FOUND = TRUE
#  GeographicLib_INCLUDE_DIRS = /usr/local/include
#  GeographicLib_LIBRARIES = /usr/local/lib/libGeographic.so
#  GeographicLib_LIBRARY_DIRS = /usr/local/lib

find_package(PkgConfig)
find_path(GeographicLib_INCLUDE_DIR GeographicLib/Config.h PATH_SUFFIXES GeographicLib)
set(GeographicLib_INCLUDE_DIRS ${GeographicLib_INCLUDE_DIR})

find_library(GeographicLib_LIBRARIES NAMES Geographic)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GeographicLib DEFAULT_MSG GeographicLib_LIBRARIES GeographicLib_INCLUDE_DIRS)
mark_as_advanced(GeographicLib_LIBRARIES GeographicLib_INCLUDE_DIRS)
