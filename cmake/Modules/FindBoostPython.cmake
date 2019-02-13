# - Try to find the a valid boost+python combination
# Once done this will define
#
#  BoostPython_FOUND - system has a valid boost+python combination
#  BoostPython_INCLUDE_DIRS - the include directory for boost+python
#  BoostPython_LIBRARIES - the needed libs for boost+python

# this only works with a recent cmake/boost combination
if(CMAKE_VERSION VERSION_GREATER 3.11)
  #find_package(Boost COMPONENTS python3.5 numpy3.5)
  find_package(Boost COMPONENTS python-py35 numpy3.5)
     FIND_PACKAGE(PythonInterp 3)
endif()

if(NOT Boost_FOUND)
  find_package(Boost REQUIRED COMPONENTS python-py35)
  set(Python_ADDITIONAL_VERSIONS 3.5)
  find_package(PythonLibs 3 REQUIRED)
   FIND_PACKAGE(PythonInterp 3)
  set(BoostPython_INCLUDE_DIRS ${Boost_INCLUDE_DIR} ${PYTHON_INCLUDE_DIR})
  set(BoostPython_LIBRARIES ${Boost_PYTHON_LIBRARIES} ${PYTHON_LIBRARIES})
else()
  find_package(Python3 REQUIRED COMPONENTS Development)
     FIND_PACKAGE(PythonInterp 3)
  set(BoostPython_INCLUDE_DIRS ${Boost_INCLUDE_DIR} ${Python3_INCLUDE_DIRS})
  set(BoostPython_LIBRARIES ${Boost_PYTHON3.5_LIBRARY} ${Boost_NUMPY3.5_LIBRARY} ${Python3_LIBRARIES})
endif()

find_package_handle_standard_args(BoostPython DEFAULT_MSG BoostPython_LIBRARIES  BoostPython_INCLUDE_DIRS)