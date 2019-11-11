cmake_minimum_required(VERSION 2.8.3)
project(mrt_cmake_modules)

find_package(catkin REQUIRED)

catkin_python_setup()

catkin_package(CFG_EXTRAS mrt_cmake_modules-extras.cmake)

## Install all cmake files
install(DIRECTORY cmake/Modules DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/cmake)
install(PROGRAMS scripts/generate_cmake_dependency_file.py DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/scripts)
install(PROGRAMS scripts/generate_cpack_cmake_file.py DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/scripts)
install(PROGRAMS scripts/packaging_update_ppa DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/scripts)
install(PROGRAMS scripts/packaging_update_rosdep_file DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/scripts)

if (MRT_ENABLE_PACKAGING)
    set(CPACK_SET_DESTDIR true)
    set(CPACK_GENERATOR DEB)
    set(CPACK_PACKAGE_NAME "mrt-ros-mrt-cmake-modules")
    set(CPACK_PACKAGE_FILE_NAME "mrt-ros-mrt-cmake-modules")
    set(CPACK_PACKAGE_VERSION "1.0.1")
    set(CPACK_DEBIAN_PACKAGE_DESCRIPTION "CMake Functions and Modules which are commonly used by MRT's ROS packages.")
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Piotr Orzechowski <piotr.orzechowski@kit.edu>")

    include(CPack)
endif()