set(PACKAGE_HEADER_FILES leptonica/allheaders.h)
set(PACKAGE_LIBRARIES lept)
set(PACKAGE_LOCAL_PATH "/mrtsoftware/pkg/local/leptonica-1.72")
set(PACKAGE_PATH "/mrtsoftware/pkg/leptonica-1.72")

find_path(Leptonica_INCLUDE_DIR NAMES ${PACKAGE_HEADER_FILES} PATHS "${PACKAGE_LOCAL_PATH}/include" "${PACKAGE_PATH}/include" /usr/local/include /usr/include)
find_library(Leptonica_LIBRARIES NAMES ${PACKAGE_LIBRARIES} PATHS "${PACKAGE_LOCAL_PATH}/lib" "${PACKAGE_PATH}/lib" /usr/local/lib /usr/lib)

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(Leptonica FOUND_VAR Leptonica_FOUND REQUIRED_VARS Leptonica_INCLUDE_DIR Leptonica_LIBRARIES)

