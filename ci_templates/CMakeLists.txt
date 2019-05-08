@  |  @ # This file contains the different versions for which file stuff is used
@  |  @ # for ros, non-ros and header only library, library or executable
@  |  @ #
@  |  @ # The mask is as follows
@  |  @ # @12|34@
@  |  @ # pos1: non ros package
@  |  @ # pos2: ros package
@  |  @ # pos3: library
@  |  @ # pos4: executable
@  |  @ #
@  |  @ # Put a "x" at the position to enable this line
@  |  @ # E.g a non-ros library has the following mask: @x |x @
@xx|xx@ set(MRT_PKG_VERSION 3.0.1)
@xx|xx@ # Modify only if you know what you are doing!
@xx|xx@ cmake_minimum_required(VERSION 3.5.1)
@xx|xx@ project(${CMAKE_PACKAGE_NAME})
@xx|xx@ 
@xx|xx@ ###################
@xx|xx@ ## Find packages ##
@xx|xx@ ###################
@xx|xx@ find_package(mrt_cmake_modules REQUIRED)
@xx|xx@ include(UseMrtStdCompilerFlags)
@xx|xx@ 
@xx|xx@ include(GatherDeps)
@xx|xx@ # Remove libs which cannot be found automatically
@xx|xx@ #list(REMOVE_ITEM DEPENDEND_PACKAGES <package name 1> <package name 2> ...)
@xx|xx@ find_package(AutoDeps REQUIRED COMPONENTS ${DEPENDEND_PACKAGES})
@xx|xx@ 
@xx|xx@ # Manually resolve removed dependend packages
@xx|xx@ #find_package(...)
@xx|xx@ 
@xx|xx@ ########################
@xx|xx@ ## Add python modules ##
@xx|xx@ ########################
@xx|xx@ # This adds a python module if located under src/{PROJECT_NAME)
@xx|xx@ mrt_python_module_setup()
@xx|xx@ 
@xx|x @ mrt_glob_files(PROJECT_PYTHON_SOURCE_FILES_SRC "python_api/*.cpp")
@xx|x @ if (PROJECT_PYTHON_SOURCE_FILES_SRC)
@xx|x @     # Add a cpp-python api library. Make sure there are no name collisions with python modules in this project
@xx|x @     mrt_add_python_api( ${PROJECT_NAME}
@xx|x @         FILES ${PROJECT_PYTHON_SOURCE_FILES_SRC}
@xx|x @         )
@xx|x @ endif()
@xx|x @ 
@ x|xx@ ################################################
@ x|xx@ ## Declare ROS messages, services and actions ##
@ x|xx@ ################################################
@ x|xx@
@ x|xx@ # Add message, service and action files
@ x|xx@ mrt_add_message_files(msg)
@ x|xx@ mrt_add_service_files(srv)
@ x|xx@ mrt_add_action_files(action)
@ x|xx@ 
@ x|xx@ # Generate added messages and services with any dependencies listed here
@ x|xx@ if (ROS_GENERATE_MESSAGES)
@ x|xx@     generate_messages(
@ x|xx@         DEPENDENCIES
@ x|xx@         #add dependencies here
@ x|xx@         #std_msgs
@ x|xx@         )
@ x|xx@ endif()
@ x|xx@ 
@ x|xx@ # Generate dynamic reconfigure options
@ x|xx@ mrt_glob_files(PARAMS_FILES "cfg/*.params" "cfg/*.cfg" "cfg/*.mrtcfg" "cfg/*.rosif")
@ x|xx@ if (PARAMS_FILES)
@ x|xx@     generate_ros_parameter_files(${PARAMS_FILES})
@ x|xx@     generate_ros_interface_files(${PARAMS_FILES})
@ x|xx@ endif()
@ x|xx@ 
@xx|x @ ############################
@xx|x @ ## Read source code files ##
@xx|x @ ############################
@xx|x @ mrt_glob_files_recurse(PROJECT_HEADER_FILES_INC "include/*.h" "include/*.hpp" "include/*.cuh")
@xx|x @ mrt_glob_files(PROJECT_SOURCE_FILES_INC "src/*.h" "src/*.hpp" "src/*.cuh")
@xx|x @ mrt_glob_files(PROJECT_SOURCE_FILES_SRC "src/*.cpp" "src/*.cu")
@xx|x @ 
@xx|x @ #################################################
@xx|x @ ## Catkin specific configuration (preparation) ##
@xx|x @ #################################################
@xx|x @ catkin_package_xml()
@xx|x @ 
@xx| x@ ###################################
@xx| x@ ## Catkin specific configuration ##
@xx| x@ ###################################
@xx| x@ catkin_package()
@xx| x@ 
@xx|xx@ ###########
@xx|xx@ ## Build ##
@xx|xx@ ###########
@xx|xx@ # Add include and library directories
@xx|xx@ include_directories(
@xx|x @     include/${PROJECT_NAME}
@xx|xx@     ${mrt_INCLUDE_DIRS}
@xx|xx@     ${catkin_INCLUDE_DIRS}
@xx|xx@     )
@xx|xx@
@xx|xx@ link_directories(
@xx|xx@     ${mrt_LIBRARY_DIRS}
@xx|xx@     )
@xx|xx@ 
@xx|x @ # Declare a cpp library
@xx|x @ mrt_add_library(${PROJECT_NAME}
@xx|x @     INCLUDES ${PROJECT_HEADER_FILES_INC} ${PROJECT_SOURCE_FILES_INC}
@xx|x @     SOURCES ${PROJECT_SOURCE_FILES_SRC}
@xx|x @     )
@xx| x@ mrt_glob_folders(SRC_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}/src")
@xx| x@ if (SRC_DIRECTORIES)
@xx| x@     # Found subfolders, add executable for each subfolder
@xx| x@     foreach(SRC_DIR ${SRC_DIRECTORIES})
@x | x@         mrt_add_executable(${SRC_DIR} FOLDER "src/${SRC_DIR}")
@ x| x@         mrt_add_node_and_nodelet(${SRC_DIR} FOLDER "src/${SRC_DIR}")
@xx| x@     endforeach()
@xx| x@ else()
@xx| x@     # No subfolder found, add executable and python modules for src folder
@x | x@     mrt_add_executable(${PROJECT_NAME} FOLDER "src")
@ x| x@     mrt_add_node_and_nodelet(${PROJECT_NAME} FOLDER "src")
@xx| x@ endif()
@xx|xx@ 
@xx|x @ ###################################
@xx|x @ ## Catkin specific configuration ##
@xx|x @ ###################################
@xx|x @ # The catkin_package macro generates cmake config files for your package
@xx|x @ # Declare things to be passed to dependent projects
@xx|x @ # INCLUDE_DIRS: uncomment this if you package contains header files
@xx|x @ # LIBRARIES: libraries you create in this project that dependent projects also need
@xx|x @ # CATKIN_DEPENDS: catkin_packages dependent projects also need
@xx|x @ # DEPENDS: system dependencies of this project that dependent projects also need
@xx|x @ catkin_package(
@xx|x @     INCLUDE_DIRS include ${mrt_EXPORT_INCLUDE_DIRS}
@xx|x @     LIBRARIES ${${PROJECT_NAME}_GENERATED_LIBRARIES} ${mrt_EXPORT_LIBRARIES}
@xx|x @     CATKIN_DEPENDS ${catkin_EXPORT_DEPENDS}
@xx|x @     )
@xx|x @ 
@xx|xx@ #############
@xx|xx@ ## Install ##
@xx|xx@ #############
@xx|xx@ # Install all targets, headers by default and scripts and other files if specified (folders or files)
@ x|xx@ mrt_install(PROGRAMS scripts FILES launch rviz maps res data nodelet_plugins.xml plugin_description.xml)
@x |xx@ mrt_install(PROGRAMS scripts FILES res data)
@xx|xx@ 
@xx|xx@ #############
@xx|xx@ ## Testing ##
@xx|xx@ #############
@xx|xx@ # Add test targets for cpp and python tests
@xx|xx@ if (CATKIN_ENABLE_TESTING)
@ x| x@     # Include header in src folder via src/<pkgname>/<myheader>.h
@ x| x@     include_directories("src")
@ x|xx@     mrt_add_ros_tests(test)
@ x|x @     mrt_add_tests(test)
@x |xx@     mrt_add_tests(test)
@xx|xx@     mrt_add_nosetests(test)
@xx|xx@ endif()
