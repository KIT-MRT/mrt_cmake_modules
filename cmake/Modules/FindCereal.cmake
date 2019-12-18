set(PACKAGE_HEADER_FILES cereal/cereal.hpp)

find_path(Cereal_INCLUDE_DIR NAMES ${PACKAGE_HEADER_FILES})

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(Cereal FOUND_VAR Cereal_FOUND REQUIRED_VARS Cereal_INCLUDE_DIR)

add_definitions(-DHAS_CEREAL)

