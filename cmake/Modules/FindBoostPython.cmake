# - Try to find the a valid boost+python combination
# Once done this will define
#
#  BoostPython_FOUND - system has a valid boost+python combination
#  BoostPython_INCLUDE_DIRS - the include directory for boost+python
#  BoostPython_LIBRARIES - the needed libs for boost+python

# this only works with a recent cmake/boost combination
#set(Python_ADDITIONAL_VERSIONS 3.6)
  #FIND_PACKAGE(PythonInterp 3)
  #set(PYTHON_EXECUTABLE /usr/bin/python3.6) 
set(CMAKE_VERBOSE_MAKEFILE ON)

set(PYTHON_VERSION 3.6)
set(PYTHON_VERSION_MAJOR 3)
set(PYTHON_VERSION_MINOR 6)
set(PYTHON_VERSION_PATCH 7)
set(PYTHON_VERSION_STRING 3.6.7)
set(_PYTHON_PATH_VERSION_SUFFIX 3.6)
#set(PYTHON_EXECUTABLE /usr/bin/python3)
set(_Python_NAMES python3)
set(CATKIN_GLOBAL_PYTHON_DESTINATION lib/python3.6/dist-packages)

set(PYTHON_INSTALL_DIR lib/python3.6/dist-packages)

  find_package(Python3 REQUIRED COMPONENTS Development)
  find_package(Boost COMPONENTS python3 numpy3 REQUIRED)
  set(BoostPython_INCLUDE_DIRS ${Boost_INCLUDE_DIR} ${Python3_INCLUDE_DIRS})
  set(BoostPython_LIBRARIES ${Boost_PYTHON3_LIBRARY} ${Boost_NUMPY3_LIBRARY} ${Python3_LIBRARIES})
  message(STATUS ${BoostPython_INCLUDE_DIRS})
MESSAGE(STATUS ${BoostPython_LIBRARIES})

    get_cmake_property(_variableNames VARIABLES)
list (SORT _variableNames)
foreach (_variableName ${_variableNames})
    message(STATUS "${_variableName}=${${_variableName}}")
endforeach()
# if(CMAKE_VERSION VERSION_GREATER 3.11)
#   #find_package(Boost COMPONENTS python3.5 numpy3.5)
#   find_package(Boost COMPONENTS python-py35 numpy3.5)
#      FIND_PACKAGE(PythonInterp 3)
# endif()
# 
# if(NOT Boost_FOUND)
#   find_package(Boost REQUIRED COMPONENTS python-py35)
#   set(Python_ADDITIONAL_VERSIONS 3.5)
#   find_package(PythonLibs 3 REQUIRED)
#    FIND_PACKAGE(PythonInterp 3)
#   set(BoostPython_INCLUDE_DIRS ${Boost_INCLUDE_DIR} ${PYTHON_INCLUDE_DIR})
#   set(BoostPython_LIBRARIES ${Boost_PYTHON_LIBRARIES} ${PYTHON_LIBRARIES})
# else()
#   find_package(Python3 REQUIRED COMPONENTS Development)
#      FIND_PACKAGE(PythonInterp 3)
#   set(BoostPython_INCLUDE_DIRS ${Boost_INCLUDE_DIR} ${Python3_INCLUDE_DIRS})
#   set(BoostPython_LIBRARIES ${Boost_PYTHON3.5_LIBRARY} ${Boost_NUMPY3.5_LIBRARY} ${Python3_LIBRARIES})
# endif()
find_package_handle_standard_args(BoostPython DEFAULT_MSG BoostPython_LIBRARIES  BoostPython_INCLUDE_DIRS)
