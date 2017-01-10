cmake_minimum_required(VERSION 2.8.3)
project(mrt_cmake_modules)

find_package(catkin REQUIRED)

catkin_python_setup()

catkin_package(CFG_EXTRAS mrt_cmake_modules-extras.cmake)

## Install all cmake files
install(DIRECTORY cmake/Modules DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/cmake)
install(PROGRAMS scripts/generate_cmake_dependency_file.py DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/scripts)
