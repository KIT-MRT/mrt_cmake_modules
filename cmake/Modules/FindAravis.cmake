include(FindPkgConfig)
pkg_check_modules(Aravis REQUIRED aravis-0.6)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Aravis DEFAULT_MSG Aravis_LIBRARIES Aravis_INCLUDE_DIRS)

mark_as_advanced(Araivs_LIBRARIES Aravis_INCLUDE_DIRS)

