macro(generate_parameter_files)
    if (${PROJECT_NAME}_CATKIN_PACKAGE)
        message(FATAL_ERROR "generate_mrt_ros_parameters() must be called before catkin_package() in project '${PROJECT_NAME}'")
    endif ()

    # ensure that package destination variables are defined
    catkin_destinations()

    # Gather all files
    file(GLOB MRT_CFG_FILES RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "cfg/*.mrtcfg")
    file(GLOB DYN_RECONF_CFG_FILES RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "cfg/*.cfg")

    set(_autogen "")
    foreach (_cfg ${MRT_CFG_FILES})
        # Construct the path to the .cfg file
        set(_input ${_cfg})
        if (NOT IS_ABSOLUTE ${_input})
            set(_input ${PROJECT_SOURCE_DIR}/${_input})
        endif ()

        # Define output files
        get_filename_component(_cfgonly ${_cfg} NAME_WE)
        set(_output_cfg ${CATKIN_DEVEL_PREFIX}/${CATKIN_PACKAGE_SHARE_DESTINATION}/cfg/${_cfgonly}.cfg)
        set(_output_cpp ${CATKIN_DEVEL_PREFIX}/${CATKIN_PACKAGE_INCLUDE_DESTINATION}/${_cfgonly}Parameters.h)

        # Create command
        assert(CATKIN_ENV)
        set(_cmd
                ${CATKIN_ENV}
                ${_input}
                ${CATKIN_DEVEL_PREFIX}/${CATKIN_PACKAGE_SHARE_DESTINATION}
                ${CATKIN_DEVEL_PREFIX}/${CATKIN_PACKAGE_INCLUDE_DESTINATION}
        )

        add_custom_command(OUTPUT
                ${_output_cpp} ${_output_cfg}
                COMMAND ${_cmd}
                DEPENDS ${_input}
                COMMENT "Generating parameter files from ${_cfgonly}"
                )

        list(APPEND DYN_RECONF_CFG_FILES "${_output_cfg}")
        list(APPEND ${PROJECT_NAME}_mrt_generated ${_output_cpp} ${_output_cfg})

        install(FILES ${_output_cpp}
                DESTINATION ${CATKIN_PACKAGE_INCLUDE_DESTINATION})

    endforeach (_cfg)

    # genparam target for hard dependency on generate_parameter generation
    add_custom_target(${PROJECT_NAME}_genparam ALL DEPENDS ${${PROJECT_NAME}_mrt_generated})

    # register target for catkin_package(EXPORTED_TARGETS)
    list(APPEND ${PROJECT_NAME}_EXPORTED_TARGETS ${PROJECT_NAME}_genparam)

    # Generate dynamic reconfigure options
    find_package(dynamic_reconfigure)
    generate_dynamic_reconfigure_options(${DYN_RECONF_CFG_FILES})

endmacro()
