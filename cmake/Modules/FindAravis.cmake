find_package(PkgConfig REQUIRED)
include(FindPkgConfig)
pkg_check_modules(PC_ARAVIS REQUIRED aravis-0.6)

set(Aravis_LIBRARIES ${PC_ARAVIS_LIBRARIES})
set(Aravis_INCLUDE_DIRS ${PC_ARAVIS_INCLUDE_DIRS})
set(Aravis_LIBRARY_DIRS ${PC_ARAVIS_LIBRARY_DIRS})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Aravis DEFAULT_MSG PC_ARAVIS_LIBRARIES PC_ARAVIS_LIBRARY_DIRS PC_ARAVIS_INCLUDE_DIRS)

mark_as_advanced(Aravis_LIBRARIES Aravis_INCLUDE_DIRS Aravis_LIBRARY_DIRS)

