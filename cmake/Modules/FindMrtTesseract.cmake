set(PACKAGE_HEADER_FILES tesseract/apitypes.h)
set(PACKAGE_LIBRARIES tesseract)
set(PACKAGE_LOCAL_PATH "/mrtsoftware/pkg/local/tesseract-3.04.00")
set(PACKAGE_PATH "/mrtsoftware/pkg/tesseract-3.04.00")

find_path(Tesseract_INCLUDE_DIR NAMES ${PACKAGE_HEADER_FILES} PATHS "${PACKAGE_LOCAL_PATH}/include" "${PACKAGE_PATH}/include" /usr/local/include /usr/include)
find_library(Tesseract_LIBRARIES NAMES ${PACKAGE_LIBRARIES} PATHS "${PACKAGE_LOCAL_PATH}/lib" "${PACKAGE_PATH}/lib" /usr/local/lib /usr/lib)

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(Tesseract FOUND_VAR Tesseract_FOUND REQUIRED_VARS Tesseract_INCLUDE_DIR Tesseract_LIBRARIES)

