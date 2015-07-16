#check if use mrt modules is included before gathering the dependencies
if (NOT DEFINED MRT_SOFTWARE_ROOT_PATH)
	message(FATAL_ERROR "MRT_SOFTWARE_ROOT_PATH is not defined. Include UseMrtModules before.")
endif()

#Add "watch" to package.xml. This is achieved by using configure_file. This is not necessary for catkin_make but
#if eclipse is used and the make target is used directly
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/package.xml" "${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/package.xml" COPYONLY)

#gather dependencies from package.xml. The command runs in python with the ros environemnt
#variable set. This is used, because the python script is calling some ros tools to distinguish
#between catkin and non catkin packages.
execute_process(COMMAND 
	python ${MRT_SOFTWARE_ROOT_PATH}/share/scripts/generate_cmake_dependency_file.py "${CMAKE_CURRENT_SOURCE_DIR}/package.xml" "${MRT_SOFTWARE_ROOT_PATH}/share/ros/base.yaml" "${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/auto_dep_vars.cmake")
	
#include the generated variable cmake file
include("${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/auto_dep_vars.cmake")

