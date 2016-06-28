find_path(GTest-headers_INCLUDE_DIRS NAMES gtest/gtest.h PATHS $ENV{GTEST_ROOT}/include ${GTEST_ROOT}/include /usr/local/include /usr/include)

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(GTest-headers FOUND_VAR GTest-headers_FOUND REQUIRED_VARS GTest-headers_INCLUDE_DIRS)

