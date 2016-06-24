################################################################################################################
#Use this block, if you have to write your own cmake find script.
#Add the header files and libraries files which are search for and adjust the
#paths as needed.
set(PACKAGE_HEADER_FILES "f2c.h")
set(PACKAGE_LIBRARIES "libf2c.a")
set(PACKAGE_LOCAL_PATH "/mrtsoftware/pkg/local/ftwoc-2.0")
set(PACKAGE_PATH "/mrtsoftware/pkg/ftwoc-2.0")

find_path(f2c_INCLUDE_DIR NAMES ${PACKAGE_HEADER_FILES} PATHS "${PACKAGE_LOCAL_PATH}/include" "${PACKAGE_PATH}/include")
find_library(f2c_LIBRARIES NAMES ${PACKAGE_LIBRARIES} PATHS "${PACKAGE_LOCAL_PATH}/lib" "${PACKAGE_PATH}/lib")

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(f2c FOUND_VAR f2c_FOUND REQUIRED_VARS f2c_INCLUDE_DIR f2c_LIBRARIES)

