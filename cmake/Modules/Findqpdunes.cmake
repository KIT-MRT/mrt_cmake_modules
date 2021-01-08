message(STATUS "Looking for qpdunes")

find_path(QPDUNES_INCLUDE_DIR
    qpDUNES.h
  HINTS /usr/local/include/qpdunes
  )

if(QPDUNES_INCLUDE_DIR)
  message(STATUS "Found qpdunes include directory: ${QPDUNES_INCLUDE_DIR}")
else()
  message(STATUS "Could not find qpdunes include dir")
endif()

find_library(QPDUNES_LIB
    NAMES qpdunes
    HINTS /usr/local/lib
)

if(QPDUNES_LIB)
  set(QPDUNES_LIBRARIES ${QPDUNES_LIB})
  message(STATUS "Found qpdunes libraries ${QPDUNES_LIBRARIES}")
  set(QPDUNES_FOUND_LIBS TRUE)
else()
  message(STATUS "Could not find qpdunes libraries")
endif()

if(QPDUNES_INCLUDE_DIR AND QPDUNES_FOUND_LIBS)
  set(QPDUNES_FOUND TRUE)
else()
  message(STATUS "QPDUNES: Cound not find qpdunes. Try setting QPDUNES env var.")
endif()
