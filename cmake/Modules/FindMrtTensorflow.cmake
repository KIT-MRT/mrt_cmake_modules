# try to find tensorflow
find_package(PkgConfig)
find_path(TENSORFLOW_INCLUDE_DIR tensorflow/core/public/session.h
  PATH_SUFFIXES tensorflow
  )

set(TENSORFLOW_INCLUDE_DIR
    ${TENSORFLOW_INCLUDE_DIR}
    ${TENSORFLOW_INCLUDE_DIR}/external/com_google_absl
    ${TENSORFLOW_INCLUDE_DIR}/external/com_google_protobuf/src
    ${TENSORFLOW_INCLUDE_DIR}/src
    ${TENSORFLOW_INCLUDE_DIR}/bazel-out/k8-opt/bin
    )

find_library(TENSORFLOW_CC_LIBRARY
  NAMES tensorflow_cc
  )
find_library(TENSORFLOW_FRAMEWORK_LIBRARY
  NAMES tensorflow_framework
  )

set(TENSORFLOW_LIBRARY ${TENSORFLOW_CC_LIBRARY})
if(TENSORFLOW_FRAMEWORK_LIBRARY)
    set(TENSORFLOW_LIBRARY ${TENSORFLOW_LIBRARY} ${TENSORFLOW_FRAMEWORK_LIBRARY})
endif(TENSORFLOW_FRAMEWORK_LIBRARY)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MrtTensorflow  DEFAULT_MSG
                                  TENSORFLOW_LIBRARY TENSORFLOW_INCLUDE_DIR)

mark_as_advanced(TENSORFLOW_LIBRARY TENSORFLOW_INCLUDE_DIR)
set(TENSORFLOW_LIBRARIES ${TENSORFLOW_LIBRARY} )
set(TENSORFLOW_INCLUDE_DIRS ${TENSORFLOW_INCLUDE_DIR} )
