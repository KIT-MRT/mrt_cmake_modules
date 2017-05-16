
# - Find NLopt
# Find the native NLopt includes and library
#
#  nlopt_INCLUDE_DIR - where to find nlopt.h, etc.
#  nlopt_LIBRARIES   - List of libraries when using nlopt.
#  nlopt_FOUND       - True if nlopt found.


IF (nlopt_INCLUDE_DIR)
  # Already in cache, be silent
  SET (nlopt_FIND_QUIETLY TRUE)
ENDIF (nlopt_INCLUDE_DIR)

FIND_PATH(nlopt_INCLUDE_DIR nlopt.h)

SET (nlopt_NAMES nlopt nlopt_cxx)
FIND_LIBRARY (nlopt_LIBRARY NAMES ${nlopt_NAMES})

# handle the QUIETLY and REQUIRED arguments and set nlopt_FOUND to TRUE if 
# all listed variables are TRUE
INCLUDE (FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS (nlopt DEFAULT_MSG 
  nlopt_LIBRARY 
  nlopt_INCLUDE_DIR)

IF(nlopt_FOUND)
  SET (nlopt_LIBRARIES ${nlopt_LIBRARY})
ELSE (nlopt_FOUND)
  SET (nlopt_LIBRARIES)
ENDIF (nlopt_FOUND)

MARK_AS_ADVANCED (nlopt_LIBRARY nlopt_INCLUDE_DIR)
