function(_mrt_export_package)
    cmake_parse_arguments(ARG "" "" "EXPORTS;LIBRARIES;TARGETS" ${ARGN})
    message(STATUS "Generating cmake exports for ${PROJECT_NAME} to ${CATKIN_DEVEL_PREFIX}/share")

    # deduplicate targets (e.g. contained by multiple variables)
    list(REMOVE_DUPLICATES ARG_TARGETS)
    # handle extras file
    set(extras_base_name ${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}-extras.cmake)
    if(EXISTS ${extras_base_name})
        message("Installing extras file '${PROJECT_NAME}-extras.cmake'")
        configure_file(${extras_base_name}
            ${CATKIN_DEVEL_PREFIX}/share/${PROJECT_NAME}/cmake/${PROJECT_NAME}-extras.cmake
            COPYONLY
            )
        install(FILES ${extras_base_name}
            DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}/cmake
            )
        # _mrt_extras_file is expected by the config.cmake
        set(_mrt_extras_file ${PROJECT_NAME}-extras.cmake)
    elseif(EXISTS ${extras_base_name}.in)
        message("Installing and configuring extras file '${PROJECT_NAME}-extras.cmake.in'")
        set(DEVELSPACE TRUE)
        set(INSTALLSPACE FALSE)
        set(PROJECT_SPACE_DIR ${CATKIN_DEVEL_PREFIX})
        set(PKG_CMAKE_DIR ${PROJECT_SPACE_DIR}/share/${PROJECT_NAME}/cmake)
        set(PKG_INCLUDE_PREFIX ${CMAKE_CURRENT_SOURCE_DIR})
        configure_file(${extras_base_name}.in
            ${CATKIN_DEVEL_PREFIX}/share/${PROJECT_NAME}/cmake/${PROJECT_NAME}-extras.cmake
            @ONLY
            )
        set(DEVELSPACE FALSE)
        set(INSTALLSPACE TRUE)
        set(PROJECT_SPACE_DIR ${CMAKE_INSTALL_PREFIX})
        set(PKG_CMAKE_DIR "\${${PROJECT_NAME}_DIR}")
        set(PKG_INCLUDE_PREFIX "\\\${prefix}")
        configure_file(${extras_base_name}.in
            ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}-extras.cmake
            @ONLY
            )
        install(FILES ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}-extras.cmake
            DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}/cmake
            )
        set(_mrt_extras_file ${PROJECT_NAME}-extras.cmake)
    elseif(EXISTS ${extras_base_name}.em)
        # TODO: This one still uses catkins functions. They should be replaced by our stuff..
        message("Installing and configuring extras file '${PROJECT_NAME}-extras.cmake.em'")
        set(DEVELSPACE TRUE)
        set(INSTALLSPACE FALSE)
        set(PROJECT_SPACE_DIR ${CATKIN_DEVEL_PREFIX})
        set(PKG_INCLUDE_PREFIX ${CMAKE_CURRENT_SOURCE_DIR})
        set(PKG_CMAKE_DIR ${PROJECT_SPACE_DIR}/share/${PROJECT_NAME}/cmake)
        em_expand(${catkin_EXTRAS_DIR}/templates/cfg-extras.context.py.in
            ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${extra}.installspace.context.cmake.py
            ${extras_base_name}.em
            ${CATKIN_DEVEL_PREFIX}/share/${PROJECT_NAME}/cmake/${PROJECT_NAME}-extras.cmake
            )
        set(DEVELSPACE FALSE)
        set(INSTALLSPACE TRUE)
        set(PROJECT_SPACE_DIR ${CMAKE_INSTALL_PREFIX})
        set(PKG_INCLUDE_PREFIX "\\\${prefix}")
        set(PKG_CMAKE_DIR "\${${PROJECT_NAME}_DIR}")
        em_expand(${catkin_EXTRAS_DIR}/templates/cfg-extras.context.py.in
            ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${extra}.installspace.context.cmake.py
            ${extras_base_name}.em
            ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}-extras.cmake
            )
        install(FILES ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}-extras.cmake
            DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}/cmake
            )
        set(_mrt_extras_file ${PROJECT_NAME}-extras.cmake)
    endif()
    if(ARG_EXPORTS)
        # these are expected by the config file
        set(_mrt_libraries)
        foreach(lib ${ARG_LIBRARIES})
            list(APPEND _mrt_libraries ${PROJECT_NAME}::${lib})
        endforeach()
        set(_mrt_targets ${ARG_TARGETS})
        export(EXPORT ${ARG_EXPORTS}
            FILE ${CATKIN_DEVEL_PREFIX}/share/${PROJECT_NAME}/cmake/${PROJECT_NAME}Targets.cmake
            NAMESPACE ${PROJECT_NAME}::
            )
        install(EXPORT ${ARG_EXPORTS}
            FILE ${PROJECT_NAME}Targets.cmake
            DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}/cmake
            NAMESPACE ${PROJECT_NAME}::
            )
        # create alias targets for multi-project builds
        foreach(lib ${export_targets})
            add_library(${PROJECT_NAME}::${lib} ALIAS ${lib})
        endforeach()
    endif()

    include(CMakePackageConfigHelpers)
    # generate the config file that includes the exports
    configure_package_config_file(${MCM_TEMPLATE_DIR}/packageConfig.cmake.in
        "${CATKIN_DEVEL_PREFIX}/share/${PROJECT_NAME}/cmake/${PROJECT_NAME}Config.cmake"
        INSTALL_DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}/cmake"
        NO_SET_AND_CHECK_MACRO
        NO_CHECK_REQUIRED_COMPONENTS_MACRO
        )
    # generate the version file for the config file
    write_basic_package_version_file(
        "${CATKIN_DEVEL_PREFIX}/share/${PROJECT_NAME}/cmake/${PROJECT_NAME}ConfigVersion.cmake"
        VERSION "${${PROJECT_NAME}_VERSION}"
        COMPATIBILITY AnyNewerVersion
        )
    install(FILES
        "${CATKIN_DEVEL_PREFIX}/share/${PROJECT_NAME}/cmake/${PROJECT_NAME}ConfigVersion.cmake"
        DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}/cmake"
        )

    # "install" the autodeps file to the devel folder
    configure_file(${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/auto_dep_vars.cmake
        ${CATKIN_DEVEL_PREFIX}/share/${PROJECT_NAME}/cmake/auto_dep_vars.cmake
        COPYONLY
        )
    # "install" findAutodeps file to the devel folder
    configure_file(${MRT_CMAKE_MODULES_CMAKE_PATH}/Modules/FindAutoDeps.cmake
        ${CATKIN_DEVEL_PREFIX}/share/${PROJECT_NAME}/cmake/${PROJECT_NAME}FindAutoDeps.cmake
        COPYONLY
        )

    # install the configuration and dependency file file
    install(FILES
        "${CATKIN_DEVEL_PREFIX}/share/${PROJECT_NAME}/cmake/${PROJECT_NAME}Config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/auto_dep_vars.cmake"
        "${CATKIN_DEVEL_PREFIX}/share/${PROJECT_NAME}/cmake/${PROJECT_NAME}FindAutoDeps.cmake"
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}/cmake
        )

    # install cmake files
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
        install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/cmake/
            DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}/cmake
            PATTERN "${PROJECT_NAME}-extras.cmake*" EXCLUDE
            )
    endif()

    # install package.xml
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/package.xml
      DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}
    )
endfunction()
