find_path(ZMQ_INCLUDE_DIR zmq.h)
find_library(ZMQ_LIBRARY NAMES zmq)

set(ZMQ_LIBRARIES ${ZMQ_LIBRARY})
set(ZMQ_INCLUDE_DIRS ${ZMQ_INCLUDE_DIR})

include(FindPackageHandleStandardArgs)

# handle the QUIETLY and REQUIRED arguments and set ZMQ_FOUND to TRUE if all listed variables are TRUE
find_package_handle_standard_args(ZMQ DEFAULT_MSG ZMQ_LIBRARY ZMQ_INCLUDE_DIR)
