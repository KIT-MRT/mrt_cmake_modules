message(STATUS "Looking for hpipm")

find_path(HPIPM_INCLUDE_DIR
    hpipm_d_ocp_qp.h
  HINTS /home/mario/MA/hpipm/include
  )

if(HPIPM_INCLUDE_DIR)
  message(STATUS "Found hpipm include directory: ${HPIPM_INCLUDE_DIR}")
else()
  message(STATUS "Could not find hpipm include dir")
endif()

find_library(HPIPM_LIB
    NAMES hpipm
    HINTS /home/mario/MA/hpipm/lib
)

if(HPIPM_LIB)
  set(HPIPM_LIBRARIES ${HPIPM_LIB})
  message(STATUS "Found hpipm libraries ${HPIPM_LIBRARIES}")
  set(HPIPM_FOUND_LIBS TRUE)
else()
  message(STATUS "Could not find hpipm libraries")
endif()

if(HPIPM_INCLUDE_DIR AND HPIPM_FOUND_LIBS)
  set(HPIPM_FOUND TRUE)
else()
  message(STATUS "HPIPM: Cound not find hpipm. Try setting HPIPM env var.")
endif()
