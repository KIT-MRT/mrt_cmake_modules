# Looks for library range-v3.

find_path(range-v3_INCLUDE_DIR range/v3/all.hpp)

mark_as_advanced(range-v3_INCLUDE_DIR)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(range-v3 REQUIRED_VARS range-v3_INCLUDE_DIR)

