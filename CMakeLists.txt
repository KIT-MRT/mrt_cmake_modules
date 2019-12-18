cmake_minimum_required(VERSION 2.8.3)
project(mrt_cmake_modules)

find_package(catkin REQUIRED)

catkin_package(CFG_EXTRAS mrt_cmake_modules-extras.cmake)

## Install all cmake files
install(DIRECTORY cmake DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION})
install(PROGRAMS scripts/generate_cmake_dependency_file.py DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/scripts)
install(FILES yaml/cmake.yaml DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/yaml)
