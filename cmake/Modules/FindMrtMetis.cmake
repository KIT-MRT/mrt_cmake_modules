set(PACKAGE_HEADER_FILES metis.h)
set(PACKAGE_LIBRARIES metis)
set(PACKAGE_LOCAL_PATH "/mrtsoftware/pkg/local/metis-4.0.3")
set(PACKAGE_PATH "/mrtsoftware/pkg/metis-4.0.3")

find_path(Metis_INCLUDE_DIR NAMES ${PACKAGE_HEADER_FILES} PATHS "${PACKAGE_LOCAL_PATH}/include" "${PACKAGE_PATH}/include")
find_library(Metis_LIBRARIES NAMES ${PACKAGE_LIBRARIES} PATHS "${PACKAGE_LOCAL_PATH}/lib" "${PACKAGE_PATH}/lib")

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(Metis FOUND_VAR Metis_FOUND REQUIRED_VARS Metis_INCLUDE_DIR Metis_LIBRARIES)

