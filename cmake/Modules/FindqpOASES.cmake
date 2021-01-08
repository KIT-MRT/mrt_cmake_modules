message(STATUS "Looking for qpOASES")

find_path(QPOASES_INCLUDE_DIR
    qpOASES.hpp
    HINTS /usr/local/include
  )

if(QPOASES_INCLUDE_DIR)
  message(STATUS "Found qpOASES include directory: ${QPOASES_INCLUDE_DIR}")
else()
  message(STATUS "Could not find qpOASES include dir")
endif()


find_library(QPOASES_LIB
    NAMES libqpOASES.so
    HINTS /usr/local/lib
)

if(QPOASES_LIB)
  set(QPOASES_LIBRARIES ${QPOASES_LIB})
  message(STATUS "Found qpOASES libraries ${QPOASES_LIBRARIES}")
  set(QPOASES_FOUND_LIBS TRUE)
else()
  message(STATUS "Could not find qpOASES libraries")
endif()

if(QPOASES_INCLUDE_DIR AND QPOASES_FOUND_LIBS)
  set(QPOASES_FOUND TRUE)
else()
  message(STATUS "QPOASES: Cound not find qpOASES. Try setting QPOASES env var.")
endif()

