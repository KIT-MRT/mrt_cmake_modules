set(PACKAGE_HEADER_FILES cereal/cereal.hpp)
set(PACKAGE_LOCAL_PATH "/mrtsoftware/pkg/local/cereal-1.1.2")
set(PACKAGE_PATH "/mrtsoftware/pkg/cereal-1.1.2")

find_path(Cereal_INCLUDE_DIR NAMES ${PACKAGE_HEADER_FILES} PATHS "${PACKAGE_LOCAL_PATH}/include" "${PACKAGE_PATH}/include")

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(Cereal FOUND_VAR Cereal_FOUND REQUIRED_VARS Cereal_INCLUDE_DIR)

add_definitions(-DHAS_CEREAL)

