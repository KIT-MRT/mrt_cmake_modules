# - Find EBUS-SDK
# Find the build components for the Pleora EBUS SDK
#
# Using EBUS-SDK:
#  find_package(ebus-sdk REQUIRED)
#  include_directories(${EBUS-SDK_INCLUDE_DIRS})
#  add_executable(foo foo.cc)
#  target_link_libraries(foo ${EBUS-SDK_LIBRARIES})
# This module sets the following variables:
#  ebus-sdk_FOUND - set to true if the library is found
#  ebus-sdk_INCLUDE_DIRS - list of required include directories
#  ebus-sdk_LIBRARIES - list of libraries to be linked
#  ebus-sdk_ROOT - the root installation directory
#
# Note: The default search path is /opt/pleora/ebus_sdk/Ubuntu-12.04-x86_64/, however the 
#       default search path may be overwritten by setting the variable MRT_EBUS_SDK_INSTALL_ROOT
if(NOT MRT_EBUS_SDK_INSTALL_ROOT) 
    set(MRT_EBUS_SDK_INSTALL_ROOT /opt/pleora/ebus_sdk/Ubuntu-12.04-x86_64/;/opt/pleora/ebus_sdk/Ubuntu-x86_64/)
endif ()

if(CMAKE_DEBUG_MESSAGES)
	message("MRT_EBUS_SDK_INSTALL_ROOT: ${MRT_EBUS_SDK_INSTALL_ROOT}")
	message(STATUS "Trying to find EBUS librarys")
endif()

### LIBRARIES ###
set(MRT_EBUS_SDK_LIB_DIR ${MRT_EBUS_SDK_INSTALL_ROOT}/lib)
find_library(EBUS_LIBS_BASE NAMES PvBase PATHS ${MRT_EBUS_SDK_LIB_DIR})
find_library(EBUS_LIBS_DEVICE NAMES PvDevice PATHS ${MRT_EBUS_SDK_LIB_DIR})
find_library(EBUS_LIBS_BUFFER NAMES PvBuffer PATHS ${MRT_EBUS_SDK_LIB_DIR})
find_library(EBUS_LIBS_GUI NAMES PvGUI PATHS ${MRT_EBUS_SDK_LIB_DIR})
find_library(EBUS_LIBS_PERSISTENCE NAMES PvPersistence PATHS ${MRT_EBUS_SDK_LIB_DIR})
find_library(EBUS_LIBS_GENICAM NAMES PvGenICam PATHS ${MRT_EBUS_SDK_LIB_DIR})
find_library(EBUS_LIBS_STREAM NAMES PvStream PATHS ${MRT_EBUS_SDK_LIB_DIR})
find_library(EBUS_LIBS_LOG4CPP NAMES log4cxx PATHS ${MRT_EBUS_SDK_LIB_DIR} NO_DEFAULT_PATH)

if(CMAKE_DEBUG_MESSAGES)
	message(STATUS "EBUS_LIBS_BASE: ${EBUS_LIBS_BASE}")
	message(STATUS "EBUS_LIBS_DEVICE: ${EBUS_LIBS_DEVICE}")
	message(STATUS "EBUS_LIBS_BUFFER: ${EBUS_LIBS_BUFFER}")
	message(STATUS "EBUS_LIBS_GUI: ${EBUS_LIBS_GUI}")
	message(STATUS "EBUS_LIBS_PERSISTENCE: ${EBUS_LIBS_PERSISTENCE}")
	message(STATUS "EBUS_LIBS_GENICAM: ${EBUS_LIBS_GENICAM}")
	message(STATUS "EBUS_LIBS_STREAM: ${EBUS_LIBS_STREAM}")
	message(STATUS "EBUS_LIBS_LOG4CPP: ${EBUS_LIBS_LOG4CPP}")
endif()

### INCLUDE PATHS
find_path(EBUS_INCLUDE_INCLUDE_DIRECTORY NAMES PvBase.h PATHS ${MRT_EBUS_SDK_INSTALL_ROOT}/include)
if(CMAKE_DEBUG_MESSAGES)
	message(STATUS "EBUS_INCLUDE_INCLUDE_DIRECTORY: ${EBUS_INCLUDE_INCLUDE_DIRECTORY}")
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
    ebus-sdk 
    FOUND_VAR ebus-sdk_FOUND
    REQUIRED_VARS  
    EBUS_LIBS_BASE
    EBUS_LIBS_DEVICE
    EBUS_LIBS_BUFFER
    EBUS_LIBS_GUI
    EBUS_LIBS_PERSISTENCE
    EBUS_LIBS_GENICAM
    EBUS_LIBS_STREAM
    EBUS_INCLUDE_INCLUDE_DIRECTORY
    EBUS_LIBS_LOG4CPP
)

if (ebus-sdk_FOUND)
    set(ebus-sdk_INCLUDE_DIRS ${EBUS_INCLUDE_INCLUDE_DIRECTORY})
    set(ebus-sdk_LIBRARIES ${EBUS_LIBS_BASE} ${EBUS_LIBS_DEVICE} ${EBUS_LIBS_BUFFER} ${EBUS_LIBS_GUI} ${EBUS_LIBS_PERSISTENCE} ${EBUS_LIBS_GENICAM} ${EBUS_LIBS_STREAM} ${EBUS_LIBS_LOG4CPP}) 
    set(ebus-sdk_ROOT ${MRT_EBUS_SDK_INSTALL_ROOT})
endif()

mark_as_advanced(
  MRT_EBUS_SDK_INSTALL_ROOT
  EBUS_INCLUDE_INCLUDE_DIRECTORY
  EBUS_LIBS_BASE
  EBUS_LIBS_DEVICE
  EBUS_LIBS_BUFFER
  EBUS_LIBS_GUI
  EBUS_LIBS_PERSISTENCE
  EBUS_LIBS_GENICAM
  EBUS_LIBS_STREAM
  EBUS_LIBS_LOG4CPP
)

