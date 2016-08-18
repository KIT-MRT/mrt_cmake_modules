macro(generate_parameter_files)
    if (${PROJECT_NAME}_CATKIN_PACKAGE)
        message(FATAL_ERROR "generate_mrt_ros_parameters() must be called before catkin_package() in project '${PROJECT_NAME}'")
    endif ()

    # ensure that package destination variables are defined
    catkin_destinations()
    find_package(rosparam_handler)



    # Gather all files
    file(GLOB MRT_CFG_FILES RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "cfg/*.mrtcfg")
    file(GLOB DYN_RECONF_CFG_FILES RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "cfg/*.cfg")
    set(PARAM_FILES ${MRT_CFG_FILES} ${DYN_RECONF_CFG_FILES})
    # generate dynamic reconfigure files
    if(rosparam_handler_FOUND_CATKIN_PROJECT)
        generate_ros_parameter_files(${PARAM_FILES})
    else()
        message(FATAL_ERROR "Dependency to rosparam_handler is missing. Can not build config files for project ${PROJECT_NAME}")
    endif()

endmacro()
