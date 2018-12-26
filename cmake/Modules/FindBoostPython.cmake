# - Try to find the a valid boost+python combination
# Once done this will define
#
#  BoostPython_FOUND - system has a valid boost+python combination
#  BoostPython_INCLUDE_DIRS - the include directory for boost+python
#  BoostPython_LIBRARIES - the needed libs for boost+python

# Copyright (c) 2006, Pino Toscano, <toscano.pino@tiscali.it>
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.

find_package(Boost REQUIRED COMPONENTS python2.7 numpy2.7)
find_package (Python2 REQUIRED COMPONENTS Development)
set(BoostPython_INCLUDE_DIRS ${Boost_INCLUDE_DIR} ${Python2_INCLUDE_DIRS})
set(BoostPython_LIBRARIES ${Boost_PYTHON2.7_LIBRARY_RELEASE} ${Python2_LIBRARIES})

find_package_handle_standard_args(BoostPython DEFAULT_MSG BoostPython_LIBRARIES  BoostPython_INCLUDE_DIRS)
