# - Try to find the a valid boost+python combination
# Once done this will define
#
#  BoostPython_FOUND - system has a valid boost+python combination
#  BoostPython_INCLUDE_DIRS - the include directory for boost+python
#  BoostPython_LIBRARIES - the needed libs for boost+python

if(CMAKE_VERSION VERSION_LESS 3.11)
  find_package(Boost REQUIRED COMPONENTS python numpy)
  set(Python_ADDITIONAL_VERSIONS "2.7")
  find_package(PythonLibs REQUIRED)
  set(BoostPython_INCLUDE_DIRS ${Boost_INCLUDE_DIR} ${PYTHON_INCLUDE_DIR})
  set(BoostPython_LIBRARIES ${Boost_PYTHON_LIBRARIES} ${Boost_NUMPY_LIBRARY} ${PYTHON_LIBRARIES})
else()
  find_package(Boost REQUIRED COMPONENTS python2.7 numpy2.7)
  find_package(Python2 REQUIRED COMPONENTS Development)
  set(BoostPython_INCLUDE_DIRS ${Boost_INCLUDE_DIR} ${Python2_INCLUDE_DIRS})
  set(BoostPython_LIBRARIES ${Boost_PYTHON2.7_LIBRARY} ${Boost_NUMPY2.7_LIBRARY} ${Python2_LIBRARIES})
endif()

find_package_handle_standard_args(BoostPython DEFAULT_MSG BoostPython_LIBRARIES  BoostPython_INCLUDE_DIRS)
