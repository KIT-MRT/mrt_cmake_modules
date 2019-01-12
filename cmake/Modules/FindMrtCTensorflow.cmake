# try to find tensorflow
find_package(PkgConfig)
find_path(TENSORFLOW_INCLUDE_DIR tensorflow/tensorflow/c/c_api.h
        PATH_SUFFIXES tensorflow
        )

set(TENSORFLOW_INCLUDE_DIR ${TENSORFLOW_INCLUDE_DIR})

find_library(TENSORFLOW_C_LIBRARY
        NAMES tensorflow
        )

set(TENSORFLOW_LIBRARY ${TENSORFLOW_C_LIBRARY})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MrtCTensorflow DEFAULT_MSG
        TENSORFLOW_LIBRARY TENSORFLOW_INCLUDE_DIR)

mark_as_advanced(TENSORFLOW_LIBRARY TENSORFLOW_INCLUDE_DIR)
set(TENSORFLOW_LIBRARIES ${TENSORFLOW_LIBRARY} )
set(TENSORFLOW_INCLUDE_DIRS ${TENSORFLOW_INCLUDE_DIR} )
