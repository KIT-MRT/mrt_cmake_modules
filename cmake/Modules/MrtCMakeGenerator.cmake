macro(generate_catkin_package  IS_ROS IS_EXEC)

include(UseMrtStdCompilerFlags)
include(UseMrtAutoTarget)
include(GatherDeps)
IF( ${IS_ROS} AND ${IS_EXEC} )
    include(MrtParamGenerator)
ENDIF()


#remove libs, which cannot be found automatically
#list(REMOVE_ITEM DEPENDEND_PACKAGES <package name 1> <package name 2> ...)
find_package(AutoDeps REQUIRED COMPONENTS ${DEPENDEND_PACKAGES})

#manually resolve removed dependend packages
#find_package(...)
@ x|xx@
@ x|xx@ ################################################
@ x|xx@ ## Declare ROS messages, services and actions ##
@ x|xx@ ################################################
@ x|xx@
@ x|xx@ # Add message, service and action files
@ x|xx@ glob_ros_files(add_message_files msg)
@ x|xx@ glob_ros_files(add_service_files srv)
@ x|xx@ glob_ros_files(add_action_files action)
@ x|xx@
@ x|xx@ # Generate added messages and services with any dependencies listed here
@ x|xx@ if (ROS_GENERATE_MESSAGES)
@ x|xx@ 	generate_messages(
@ x|xx@ 	  DEPENDENCIES
@ x|xx@ 	  #add dependencies here
@ x|xx@ 	  #std_msgs
@ x|xx@ 	)
@ x|xx@ endif()
@ x|xx@
@ x|xx@ # Generate dynamic reconfigure options
@ x|xx@ file(GLOB CFG_FILES RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "cfg/*cfg")
@ x|xx@ file(GLOB SRV_FILES RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "srv/*.srv")
@ x|xx@ if (CFG_FILES)
@ x|xx@   generate_parameter_files()
@ x|xx@ endif ()
@ x|xx@
@ x|xx@
@xx|x @ ############################
@xx|x @ ## read source code files ##
@xx|x @ ############################
@xx|x @ file(GLOB_RECURSE PROJECT_HEADER_FILES_INC RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "include/*.h" "include/*.hpp")
@xx|x @ file(GLOB PROJECT_SOURCE_FILES_INC RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "src/*.h" "src/*.hpp")
@xx|x @ file(GLOB PROJECT_SOURCE_FILES_SRC RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "src/*.cpp")
@xx|x @
@xx|x @ if (PROJECT_SOURCE_FILES_SRC)
@xx|x @ 	set(LIBRARY_NAME ${PROJECT_NAME})
@xx|x @ endif()

###################################
## catkin specific configuration ##
###################################
@xx|x @ # The catkin_package macro generates cmake config files for your package
@xx|x @ # Declare things to be passed to dependent projects
@xx|x @ # INCLUDE_DIRS: uncomment this if you package contains header files
@xx|x @ # LIBRARIES: libraries you create in this project that dependent projects also need
@xx|x @ # CATKIN_DEPENDS: catkin_packages dependent projects also need
@xx|x @ # DEPENDS: system dependencies of this project that dependent projects also need
catkin_package(
@xx|x @   INCLUDE_DIRS include ${mrt_EXPORT_INCLUDE_DIRS}
@xx|x @   LIBRARIES ${LIBRARY_NAME} ${mrt_EXPORT_LIBRARIES}
@xx|x @   CATKIN_DEPENDS ${catkin_EXPORT_DEPENDS}
)

###########
## Build ##
###########
# Add include and library directories
include_directories(
@xx|x @   include/${LIBRARY_NAME}
  ${mrt_INCLUDE_DIRS}
  ${catkin_INCLUDE_DIRS}
)

link_directories(
  ${mrt_LIBRARY_DIRS}
)

@xx|x @ if (PROJECT_SOURCE_FILES_SRC)
@xx|x @ 	# Declare a cpp library
@xx|x @ 	add_library(${LIBRARY_NAME}
@xx|x @ 	  ${PROJECT_HEADER_FILES_INC}
@xx|x @ 	  ${PROJECT_SOURCE_FILES_INC}
@xx|x @ 	  ${PROJECT_SOURCE_FILES_SRC}
@xx|x @ 	)
@xx|x @
@ x|x @ 	# Add cmake target dependencies of the executable/library
@ x|x @ 	# as an example, message headers may need to be generated before nodes
@ x|x @ 	add_dependencies(${LIBRARY_NAME} ${catkin_EXPORTED_TARGETS})
@ x|x @ 	if (ROS_GENERATE_MESSAGES)
@ x|x @ 	      add_dependencies(${LIBRARY_NAME} ${PROJECT_NAME}_generate_messages)
@ x|x @ 	endif()
@ x|x @
@xx|x @ 	# Specify libraries to link a library or executable target against
@xx|x @ 	target_link_libraries(${LIBRARY_NAME}
@xx|x @ 	  ${catkin_LIBRARIES}
@xx|x @ 	  ${mrt_LIBRARIES}
@xx|x @ 	)
@xx|x @ endif()
@xx|x @
@xx| x@ function(add_exec EXEC_NAME SEARCH_FOLDER)
@xx| x@ 	#glob all files in this directory
@xx| x@ 	file(GLOB EXEC_SOURCE_FILES_INC RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${SEARCH_FOLDER}/*.h" "${SEARCH_FOLDER}/*.hpp")
@xx| x@ 	file(GLOB EXEC_SOURCE_FILES_SRC RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${SEARCH_FOLDER}/*.cpp")
@xx| x@
@xx| x@ 	if (EXEC_SOURCE_FILES_SRC)
@xx| x@ 		#add executable
@xx| x@ 		add_executable(${EXEC_NAME}
@xx| x@ 			${EXEC_SOURCE_FILES_INC}
@xx| x@ 			${EXEC_SOURCE_FILES_SRC}
@xx| x@ 		)
@xx| x@
@ x| x@ 		# Add cmake target dependencies of the executable/library
@ x| x@ 		# as an example, message headers may need to be generated before nodes
@ x| x@ 		add_dependencies(${EXEC_NAME} ${catkin_EXPORTED_TARGETS})
@ x| x@ 		if (CFG_FILES)
@ x| x@ 			add_dependencies(${EXEC_NAME} ${PROJECT_NAME}_gencfg)
@ x| x@ 		endif()
@ x| x@ 		if (SRV_FILES)
@ x| x@ 			add_dependencies(${EXEC_NAME} ${PROJECT_NAME}_gencpp)
@ x| x@ 		endif()
@ x| x@ 	    if (ROS_GENERATE_MESSAGES)
@ x| x@ 	      add_dependencies(${EXEC_NAME} ${PROJECT_NAME}_generate_messages)
@ x| x@ 	    endif()
@ x| x@
@xx| x@ 		# Specify libraries to link a library or executable target against
@xx| x@ 		target_link_libraries(${EXEC_NAME}
@xx| x@ 		  ${catkin_LIBRARIES}
@xx| x@ 		  ${mrt_LIBRARIES}
@xx| x@ 		)
@xx| x@
@xx| x@ 		# Mark executables and/or libraries for installation
@xx| x@ 		install(TARGETS ${EXEC_NAME}
@xx| x@ 		  ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
@xx| x@ 		  LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
@xx| x@ 		  RUNTIME DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
@xx| x@ 		)
@xx| x@ 	endif()
@xx| x@ endfunction()
@xx| x@
@ x| x@ function(add_nodelet EXEC_NAME SEARCH_FOLDER)
@ x| x@ 	#glob all files in this directory
@ x| x@ 	file(GLOB EXEC_SOURCE_FILES_INC RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${SEARCH_FOLDER}/*.h" "${SEARCH_FOLDER}/*.hpp")
@ x| x@ 	file(GLOB EXEC_SOURCE_FILES_SRC RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${SEARCH_FOLDER}/*.cpp")
@ x| x@
@ x| x@     # Find nodelet
@ x| x@ 	file(GLOB NODELET_CPP RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${SEARCH_FOLDER}/*_nodelet.cpp")
@ x| x@ 	if (NODELET_CPP)
@ x| x@         STRING(REGEX REPLACE "_node" "" NODELET_NAME ${EXEC_NAME})
@ x| x@         add_library(${NODELET_NAME}_nodelet
@ x| x@             ${EXEC_SOURCE_FILES_INC}
@ x| x@ 			${EXEC_SOURCE_FILES_SRC}
@ x| x@         )
@ x| x@         target_link_libraries(${NODELET_NAME}_nodelet
@ x| x@             ${catkin_LIBRARIES}
@ x| x@             ${mrt_LIBRARIES}
@ x| x@         )
@ x| x@         install(TARGETS ${NODELET_NAME}_nodelet
@ x| x@             LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
@ x| x@         )
@ x| x@     endif()
@ x| x@ endfunction()
@ x| x@
@xx| x@ glob_folders(SRC_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}/src")
@xx| x@
@xx| x@ if (SRC_DIRECTORIES)
@xx| x@ 	#found subfolders, add executable for each subfolder
@xx| x@ 	foreach(SRC_DIR ${SRC_DIRECTORIES})
@xx| x@ 		add_exec(${SRC_DIR} "src/${SRC_DIR}")
@ x| x@ 		add_nodelet(${SRC_DIR} "src/${SRC_DIR}")
@xx| x@ 	endforeach()
@xx| x@ else()
@xx| x@ 	#no subfolder found, add executable for src folder
@xx| x@ 	add_exec(${PROJECT_NAME} "src")
@ x| x@ 	add_nodelet(${PROJECT_NAME} "src")
@xx| x@ endif()

#############
## Install ##
#############
@xx|x @ if (TARGET ${PROJECT_NAME})
@xx|x @ 	# Mark library for installation
@xx|x @ 	install(TARGETS ${PROJECT_NAME}
@xx|x @ 	  ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
@xx|x @ 	  LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
@xx|x @ 	  RUNTIME DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
@xx|x @ 	)
@xx|x @ endif()
@xx|x @
@xx|x @ # Mark c++ header files for installation
@xx|x @ install(DIRECTORY include/${PROJECT_NAME}/
@xx|x @   DESTINATION ${CATKIN_PACKAGE_INCLUDE_DESTINATION}
@xx|x @   FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp"
@xx|x @ )
@xx|x @
#install(FILES
#  res/test.png
#  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
#)
@ x| x@
@ x| x@ # Find and install nodelet plugin description file
@ x| x@ file(GLOB PLUGINS_FILE RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "nodelet_plugins.xml")
@ x| x@ if (PLUGINS_FILE)
@ x| x@     install(FILES nodelet_plugins.xml
@ x| x@             DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION})
@ x| x@ endif()

#############
## Testing ##
#############
# Add gtest based cpp test target and link libraries
if (CATKIN_ENABLE_TESTING)
	file(GLOB PROJECT_TEST_FILES_SRC RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "test/*.cpp")
	foreach(PROJECT_TEST_FILE_SRC ${PROJECT_TEST_FILES_SRC})
		get_filename_component(PROJECT_TEST_NAME ${PROJECT_TEST_FILE_SRC} NAME_WE)

		catkin_add_gtest(${PROJECT_NAME}-${PROJECT_TEST_NAME}-test ${PROJECT_TEST_FILE_SRC})
@xx|x @ 		target_link_libraries(${PROJECT_NAME}-${PROJECT_TEST_NAME}-test ${LIBRARY_NAME} ${catkin_LIBRARIES} ${mrt_LIBRARIES} gtest_main)
@xx| x@ 		target_link_libraries(${PROJECT_NAME}-${PROJECT_TEST_NAME}-test ${catkin_LIBRARIES} ${mrt_LIBRARIES} gtest_main)
	endforeach()
endif()

endmacro()

