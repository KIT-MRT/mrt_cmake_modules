# Generated from: mrt_cmake_modules/cmake/mrt_cmake_modules-extra.cmake.em
if(_MRT_CMAKE_MODULES_EXTRAS_INCLUDED_)
    return()
endif()
set(_MRT_CMAKE_MODULES_EXTRAS_INCLUDED_ TRUE)

# Check cmakelists version
set(_MRT_RECOMMENDED_VERSION 2.1)
if(MRT_PKG_VERSION VERSION_LESS _MRT_RECOMMENDED_VERSION )
   message(WARNING "Current CMakeLists.txt version is less than the recommended version ${_MRT_RECOMMENDED_VERSION}. If you are the maintainer, please update it with\n'mrt maintenance update_cmakelists ${PROJECT_NAME}'.")
endif()

# Set the cmake install path
@[if DEVELSPACE]@
# cmake dir in develspace
list(APPEND CMAKE_MODULE_PATH "@(PROJECT_SOURCE_DIR)/cmake/Modules")
@[else]@
# cmake dir in installspace
list(APPEND CMAKE_MODULE_PATH "@(PKG_CMAKE_DIR)/Modules")
@[end if]@
set(MCM_ROOT "@(CMAKE_CURRENT_SOURCE_DIR)")

# care for clang-tidy flags
if(MRT_CLANG_TIDY STREQUAL "check")
    set(MRT_CLANG_TIDY_FLAGS "-extra-arg=-Wno-unknown-warning-option" "-header-filter=${PROJECT_SOURCE_DIR}/.*")
elseif(MRT_CLANG_TIDY STREQUAL "fix")
    set(MRT_CLANG_TIDY_FLAGS "-extra-arg=-Wno-unknown-warning-option" "-fix-errors" "-header-filter=${PROJECT_SOURCE_DIR}/.*" "-format-style=file")
endif()
if(DEFINED MRT_CLANG_TIDY_FLAGS)
    if(${CMAKE_VERSION} VERSION_LESS "3.6.0")
        message(WARNING "Using clang-tidy requires at least CMAKE 3.6.0. Please upgrade CMake.")
    endif()
    find_package(ClangTidy)
    if(ClangTidy_FOUND)
        message(STATUS "Add clang tidy flags")
        set(CMAKE_CXX_CLANG_TIDY "${ClangTidy_EXE}" "${MRT_CLANG_TIDY_FLAGS}")
    else()
        message(WARNING "Failed to find clang-tidy. Is it installed?")
    endif()
endif()

# cache or load environment for non-catkin build
if( NOT DEFINED CATKIN_DEVEL_PREFIX AND EXISTS "${CMAKE_CURRENT_BINARY_DIR}/mrt_cached_variables.cmake")
    message(STATUS "Non-catkin build detected. Loading cached variables from last catkin run.")
    include("${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/mrt_cached_variables.cmake")
else()
    set(_ENV_CMAKE_PREFIX_PATH $ENV{CMAKE_PREFIX_PATH})
    configure_file(${MCM_ROOT}/cmake/Templates/mrt_cached_variables.cmake.in "${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/mrt_cached_variables.cmake" @@ONLY)
endif()


# Set build flags to MRT_SANITIZER_CXX_FLAGS based on the current sanitizer configuration
# based on the configruation in the MRT_SANITIZER variable
if(MRT_SANITIZER STREQUAL "checks")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 6.3)
        set(MRT_SANITIZER_CXX_FLAGS "-fsanitize=undefined,bounds-strict,float-divide-by-zero,float-cast-overflow" "-fsanitize-recover=alignment")
        set(MRT_SANITIZER_EXE_CXX_FLAGS "-fsanitize=address,leak,undefined,bounds-strict,float-divide-by-zero,float-cast-overflow" "-fsanitize-recover=alignment")
        set(MRT_SANITIZER_LINK_FLAGS "-static-libasan" "-lubsan")
    elseif(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 4.9)
        set(MRT_SANITIZER_CXX_FLAGS "-fsanitize=undefined,float-divide-by-zero,float-cast-overflow" "-fsanitize-recover=alignment")
        set(MRT_SANITIZER_EXE_CXX_FLAGS "-fsanitize=address,leak,undefined,float-divide-by-zero,float-cast-overflow" "-fsanitize-recover=alignment")
        set(MRT_SANITIZER_LINK_FLAGS "-static-libasan" "-lubsan")
    endif()
    set(MRT_SANITIZER_ENABLED 1)
elseif(MRT_SANITIZER STREQUAL "check_race")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 6.3)
        set(MRT_SANITIZER_CXX_FLAGS "-fsanitize=thread,undefined,bounds-strict,float-divide-by-zero,float-cast-overflow")
    elseif(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 4.9)
        set(MRT_SANITIZER_CXX_FLAGS "-fsanitize=thread,undefined,float-divide-by-zero,float-cast-overflow")
    endif()
    set(MRT_SANITIZER_LINK_FLAGS "-static-libtsan")
    set(MRT_SANITIZER_ENABLED 1)
endif()
if(MRT_SANITIZER_ENABLED AND MRT_SANITIZER_RECOVER STREQUAL "no_recover")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 6.3)
        set(MRT_SANITIZER_CXX_FLAGS "-fno-sanitize-recover=undefined,bounds-strict,float-divide-by-zero,float-cast-overflow" ${MRT_SANITIZER_CXX_FLAGS})
    elseif(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 4.9)
        set(MRT_SANITIZER_CXX_FLAGS "-fno-sanitize-recover=undefined,float-divide-by-zero,float-cast-overflow" ${MRT_SANITIZER_CXX_FLAGS})
    endif()
endif()

# define rosparam/rosinterface_handler macro for compability. Macros will be overriden by the actual macros defined by the packages, if existing.
macro(generate_ros_parameter_files)
    # handle pure dynamic reconfigure files
    foreach (_cfg ${ARGN})
        get_filename_component(_cfgext ${_cfg} EXT)
        if( _cfgext STREQUAL ".cfg" )
            list(APPEND _${PROJECT_NAME}_pure_cfg_files "${_cfg}")
        else()
            list(APPEND _${PROJECT_NAME}_rosparam_other_param_files "${_cfg}")
        endif()
    endforeach()
    # generate dynamic reconfigure files
    if(_${PROJECT_NAME}_pure_cfg_files AND NOT TARGET ${PROJECT_NAME}_gencfg AND NOT rosinterface_handler_FOUND_CATKIN_PROJECT)
        if(dynamic_reconfigure_FOUND_CATKIN_PROJECT)
            generate_dynamic_reconfigure_options(${_${PROJECT_NAME}_pure_cfg_files})
        else()
            message(WARNING "Dependency to dynamic_reconfigure is missing, or find_package(dynamic_reconfigure) was not called yet. Not building dynamic config files")
        endif()
    endif()
    # if there are other config files, someone will have forgotten to include the rosparam/rosinterface handler
    if(_${PROJECT_NAME}_rosparam_other_param_files AND NOT rosinterface_handler_FOUND_CATKIN_PROJECT)
        message(FATAL_ERROR "Dependency rosinterface_handler or rosparam_handler could not be found. Did you add it to your package.xml?")
    endif()
endmacro()
macro(generate_ros_interface_files)
    # handle pure dynamic reconfigure files
    foreach (_cfg ${ARGN})
        get_filename_component(_cfgext ${_cfg} EXT)
        if(NOT _cfgext STREQUAL ".cfg" )
            list(APPEND _${PROJECT_NAME}_rosif_other_param_files "${_cfg}")
        endif()
    endforeach()
    if(_${PROJECT_NAME}_rosif_other_param_files AND NOT rosparam_handler_FOUND_CATKIN_PROJECT)
        message(FATAL_ERROR "Dependency rosinterface_handler or rosparam_handler could not be found. Did you add it to your package.xml?")
    endif()
endmacro()

macro(_setup_coverage_info)
    setup_target_for_coverage(${PROJECT_NAME}-coverage coverage ${PROJECT_NAME}-pre-coverage)
    # make sure the target is built after running tests
    add_dependencies(run_tests ${PROJECT_NAME}-coverage)
    add_dependencies(${PROJECT_NAME}-coverage _run_tests_${PROJECT_NAME})
    if(TARGET ${PROJECT_NAME}-pre-coverage)
        add_dependencies(clean_test_results_${PROJECT_NAME} ${PROJECT_NAME}-pre-coverage)
        add_dependencies(${PROJECT_NAME}-pre-coverage tests)
    endif()
    if(MRT_ENABLE_COVERAGE GREATER 1)
        add_custom_command(TARGET ${PROJECT_NAME}-coverage
            POST_BUILD
            COMMAND firefox ${CMAKE_CURRENT_BINARY_DIR}/coverage/index.html > /dev/null 2>&1 &
            COMMENT "Showing coverage results"
            )
    endif()
endmacro()


#
# Registers the custom check_tests command and adds a dependency for a certain unittest
#
# Example:
# ::
#
#  _mrt_register_test(
#      )
#
macro(_mrt_register_test)
    # we need this only once per project
    if(MRT_NO_FAIL_ON_TESTS OR _mrt_checks_${PROJECT_NAME} OR NOT TARGET _run_tests_${PROJECT_NAME})
        return()
    endif()
    # pygment formats xml more nicely
    find_program(CCAT pygmentize)
    if(CCAT)
        set(RUN_CCAT | ${CCAT})
    endif()

    add_custom_command(TARGET _run_tests_${PROJECT_NAME}
        POST_BUILD
        COMMAND /bin/bash -c \"set -o pipefail$<SEMICOLON> catkin_test_results --verbose . ${RUN_CCAT} 1>&2\" # redirect to stderr for better output in catkin
        WORKING_DIRECTORY ${CMAKE_CURRENT_BUILD_DIR}
        COMMENT "Showing test results"
        )
    set(_mrt_checks_${PROJECT_NAME} TRUE PARENT_SCOPE)
endmacro()

# Glob for folders in the search directory.
function(mrt_glob_folders DIRECTORY_LIST SEARCH_DIRECTORY)
    if(${CMAKE_VERSION} VERSION_LESS "3.12.0")
        file(GLOB DIRECTORIES "${SEARCH_DIRECTORY}/[^.]*")
    else()
        file(GLOB DIRECTORIES CONFIGURE_DEPENDS "${SEARCH_DIRECTORY}/[^.]*")
    endif()

    set(_DIRECTORY_LIST_ "")
    foreach(SRC_DIR ${DIRECTORIES})
        if(IS_DIRECTORY "${SRC_DIR}")
            get_filename_component(DIRECTORY_NAME "${SRC_DIR}" NAME)
            list(APPEND _DIRECTORY_LIST_ ${DIRECTORY_NAME})
        endif()
    endforeach()
    set(${DIRECTORY_LIST} ${_DIRECTORY_LIST_} PARENT_SCOPE)
endfunction()

# Deprecated function. Use 'mrt_glob_folders' instead.
macro(glob_folders)
    mrt_glob_folders(${ARGV})
endmacro()

# Globs for message files and calls add_message_files
macro(mrt_add_message_files folder_name)
    mrt_glob_files(_ROS_MESSAGE_FILES REL_FOLDER ${folder_name} ${folder_name}/*.msg)
    if (_ROS_MESSAGE_FILES)
        add_message_files(FILES ${_ROS_MESSAGE_FILES} DIRECTORY "${CMAKE_CURRENT_LIST_DIR}/${folder_name}")
        set(ROS_GENERATE_MESSAGES True)
    endif()
endmacro()

# Globs for service files and calls add_service_files
macro(mrt_add_service_files folder_name)
    mrt_glob_files(_ROS_SERVICE_FILES REL_FOLDER ${folder_name} ${folder_name}/*.srv)
    if (_ROS_SERVICE_FILES)
        add_service_files(FILES ${_ROS_SERVICE_FILES} DIRECTORY "${CMAKE_CURRENT_LIST_DIR}/${folder_name}")
        set(ROS_GENERATE_MESSAGES True)
    endif()
endmacro()

# Globs for action files and calls add_action_files
macro(mrt_add_action_files folder_name)
    mrt_glob_files(_ROS_ACTION_FILES REL_FOLDER ${folder_name} ${folder_name}/*.action)
    if (_ROS_ACTION_FILES)
        add_action_files(FILES ${_ROS_ACTION_FILES} DIRECTORY "${CMAKE_CURRENT_LIST_DIR}/${folder_name}")
    endif()
endmacro()

# Deprecated function. Use one of 'mrt_add_message_files', 'mrt_add_service_files' or 'mrt_add_action_files'.
macro(glob_ros_files excecutable_name extension_name)
    mrt_glob_files(ROS_${excecutable_name}_FILES REL_FOLDER ${extension_name} "${extension_name}/*.${extension_name}")

    if (ROS_${excecutable_name}_FILES)
        #work around to execute a command wich name is given in a variable
        #write a file with the command, include it and delete the file again
        file(WRITE "${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/_GLOB_ROS_TEMP_FILE.cmake" "${excecutable_name}(
            DIRECTORY \"${PROJECT_SOURCE_DIR}/${extension_name}\"
            FILES
            ${ROS_${excecutable_name}_FILES}
            )")
        include("${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/_GLOB_ROS_TEMP_FILE.cmake")
        file(REMOVE "${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/_GLOB_ROS_TEMP_FILE.cmake")

        set(ROS_GENERATE_MESSAGES True)
    endif()
endmacro()

# Globs files in the currect project dir.
function(mrt_glob_files varname)
    cmake_parse_arguments(PARAMS "" "REL_FOLDER" "" ${ARGN})

    if (PARAMS_REL_FOLDER)
        set(RELATIVE_PATH "${PROJECT_SOURCE_DIR}/${PARAMS_REL_FOLDER}")
    else()
        set(RELATIVE_PATH "${PROJECT_SOURCE_DIR}")
    endif()

    if(${CMAKE_VERSION} VERSION_LESS "3.12.0")
        file(GLOB files RELATIVE "${RELATIVE_PATH}" ${PARAMS_UNPARSED_ARGUMENTS})
    else()
        file(GLOB files RELATIVE "${RELATIVE_PATH}" CONFIGURE_DEPENDS ${PARAMS_UNPARSED_ARGUMENTS})
    endif()
    set(${varname} ${files} PARENT_SCOPE)
endfunction()

# Globs files recursivly in the currect project dir.
function(mrt_glob_files_recurse varname)
    cmake_parse_arguments(PARAMS "" "REL_FOLDER" "" ${ARGN})

    if (PARAMS_REL_FOLDER)
        set(RELATIVE_PATH "${PROJECT_SOURCE_DIR}/${PARAMS_REL_FOLDER}")
    else()
        set(RELATIVE_PATH "${PROJECT_SOURCE_DIR}")
    endif()

    if(${CMAKE_VERSION} VERSION_LESS "3.12.0")
        file(GLOB_RECURSE files RELATIVE "${RELATIVE_PATH}" ${PARAMS_UNPARSED_ARGUMENTS})
    else()
        file(GLOB_RECURSE files RELATIVE "${RELATIVE_PATH}" CONFIGURE_DEPENDS ${PARAMS_UNPARSED_ARGUMENTS})
    endif()
    set(${varname} ${files} PARENT_SCOPE)
endfunction()

#
# Once upon a time this used to make non-code files known to IDEs that parse Cmake output. But as this
# messes up with the target determination mechanism used by most ides and garbages up the target view.
#
# Therefore this function is no longer used and only here for backwards compability.
#
# @@public
#
function(mrt_add_to_ide files)
endfunction()

#
# Automatically sets up and installs python modules located under ``src/${PROJECT_NAME}``.
# Modules can afterwards simply be included using "import <project_name>" in python.
#
# The python folder (under src/${PROJECT_NAME}) is required to have an __init__.py file.
#
# The command will automatically generate a setup.py in your project folder.
# This file should not be commited, as it will be regenerated at every new CMAKE run.
# Due to restrictions imposed by catkin (searches hardcoded for this setup.py), the file cannot
# be placed elsewhere.
#
# Example:
# ::
#
#   mrt_python_module_setup()
#
# @@public
#
function(mrt_python_module_setup)
    if(NOT catkin_FOUND)
        find_package(catkin REQUIRED)
    endif()
    if(ARGN)
        message(FATAL_ERROR "mrt_python_module_setup() called with unused arguments: ${ARGN}")
    endif()
    if(NOT EXISTS "${PROJECT_SOURCE_DIR}/src/${PROJECT_NAME}/__init__.py")
        return()
    endif()
    set(PKG_PYTHON_MODULE ${PROJECT_NAME})
    set(${PROJECT_NAME}_PYTHON_MODULE ${PROJECT_NAME} PARENT_SCOPE)
    set(PACKAGE_DIR "src")
    configure_file(${MCM_ROOT}/cmake/Templates/setup.py.in "${PROJECT_SOURCE_DIR}/setup.py" @@ONLY)
    catkin_python_setup()
endfunction()


#
# Generates a python module from boost-python cpp files.
#
# Each <file>.cpp will become a seperate <file>.py submodule within <modulename>. After building and sourcing you can use the modules simply with "import <modulename>.<file>".
#
# The files are automatically linked with boost-python libraries and a python module is generated
# and installed from the resulting library. If this project declares any libraries with ``mrt_add_library()``, they will automatically be linked with this library.
#
# This function will define the compiler variable ``PYTHON_API_MODULE_NAME`` with the name of the generated library. This can be used in the ``BOOST_PYTHON_MODULE`` C++ Macro.
#
# .. note:: This function can only be called once per package.
#
# :param modulename: Name of the module needs to be passed as first parameter.
# :type modulename: string
# :param FILES: list of C++ files defining the BOOST-Python API.
# :type FILES: list of strings
#
# Example:
# ::
#
#   mrt_add_python_api( example_package
#       FILES python_api/python.cpp
#       )
#
# @@public
#
function(mrt_add_python_api modulename)
    cmake_parse_arguments(MRT_ADD_PYTHON_API "" "" "FILES" ${ARGN})
    if(NOT MRT_ADD_PYTHON_API_FILES)
        return()
    endif()

    #set and check target name
    set( PYTHON_API_MODULE_NAME ${modulename})
    if("${${PROJECT_NAME}_PYTHON_MODULE}" STREQUAL "${PYTHON_API_MODULE_NAME}")
        message(FATAL_ERROR "The name of the python_api module conflicts with the name of the python module. Please choose a different name")
    endif()

    if("${PYTHON_API_MODULE_NAME}" STREQUAL "${PROJECT_NAME}")
        # mark that catkin_python_setup() was called and the setup.py file contains a package with the same name as the current project
        # in order to disable installation of generated __init__.py files in generate_messages() and generate_dynamic_reconfigure_options()
        set(${PROJECT_NAME}_CATKIN_PYTHON_SETUP_HAS_PACKAGE_INIT TRUE PARENT_SCOPE)
    endif()
    if(${PROJECT_NAME}_PYTHON_API_TARGET)
        message(FATAL_ERROR "mrt_add_python_api() was already called for this project. You can add only one python_api per project!")
    endif()

    if (NOT pybind11_FOUND AND NOT BoostPython_FOUND)
        message(FATAL_ERROR "Missing dependency to pybind11 or boost python. Add either '<depend>pybind11-dev</depend>' or '<depend>libboost-python</depend>' to 'package.xml'")
    endif()

    if (pybind11_FOUND AND BoostPython_FOUND)
        message(FATAL_ERROR "Found pybind11 and boost python. Only one is allowed.")
    endif()

    # put in devel folder
    set(DEVEL_PREFIX  ${CATKIN_DEVEL_PREFIX})
    set(PYTHON_MODULE_DIR ${DEVEL_PREFIX}/${CATKIN_GLOBAL_PYTHON_DESTINATION}/${PYTHON_API_MODULE_NAME})

    # add library for each file
    foreach(API_FILE ${MRT_ADD_PYTHON_API_FILES})
        get_filename_component(SUBMODULE_NAME ${API_FILE} NAME_WE)
        set( TARGET_NAME "${PROJECT_NAME}-${PYTHON_API_MODULE_NAME}-${SUBMODULE_NAME}-pyapi")
        set( LIBRARY_NAME ${SUBMODULE_NAME})
        message(STATUS "Adding python api library \"${LIBRARY_NAME}\" to python module \"${PYTHON_API_MODULE_NAME}\"")

        if (pybind11_FOUND)
            pybind11_add_module(${TARGET_NAME} MODULE ${API_FILE})
            target_link_libraries(${TARGET_NAME} PRIVATE pybind11::module)
        elseif(BoostPython_FOUND)
            add_library(${TARGET_NAME} SHARED ${API_FILE})
            target_link_libraries(${TARGET_NAME} PRIVATE ${BoostPython_LIBRARIES} ${PYTHON_LIBRARY})
        endif()

        set_target_properties(${TARGET_NAME}
            PROPERTIES OUTPUT_NAME ${LIBRARY_NAME}
            PREFIX ""
            )
        
        set_target_properties(${TARGET_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${PYTHON_MODULE_DIR}")

        target_compile_definitions(${TARGET_NAME} PRIVATE -DPYTHON_API_MODULE_NAME=${LIBRARY_NAME})
        
        target_link_libraries( ${TARGET_NAME} PRIVATE
            ${catkin_LIBRARIES}
            ${mrt_LIBRARIES}
            ${MRT_SANITIZER_LINK_FLAGS}
            )

        set(_deps ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS})
        if(_deps)
            add_dependencies(${TARGET_NAME} ${_deps})
        endif()
        list(APPEND GENERATED_TARGETS ${TARGET_NAME} )
    endforeach()
    configure_file(${MCM_ROOT}/cmake/Templates/__init__.py.in ${PYTHON_MODULE_DIR}/__init__.py)

    # append to list of all targets in this project
    set(${PROJECT_NAME}_PYTHON_API_TARGET ${GENERATED_TARGETS} PARENT_SCOPE)

    # configure setup.py for install
    set(PKG_PYTHON_MODULE ${PYTHON_API_MODULE_NAME})
    set(PACKAGE_DIR ${DEVEL_PREFIX}/${CATKIN_GLOBAL_PYTHON_DESTINATION})
    set(PACKAGE_DATA "*.so*")
    configure_file(${MCM_ROOT}/cmake/Templates/setup.py.in "${CMAKE_CURRENT_BINARY_DIR}/setup.py" @@ONLY)
    configure_file(${MCM_ROOT}/cmake/Templates/python_api_install.py.in "${CMAKE_CURRENT_BINARY_DIR}/python_api_install.py" @@ONLY)
    install(CODE "execute_process(COMMAND ${CMAKE_CURRENT_BINARY_DIR}/python_api_install.py)")
endfunction()


#
# Adds a library.
#
# This command ensures the library is compiled with all necessary dependencies. If no files are passed, the command will return silently.
#
# .. note:: Make sure to call this after all messages and parameter generation CMAKE-Commands so that all dependencies are visible.
#
# The files are automatically added to the list of installable targets so that ``mrt_install`` can mark them for installation.
#
# :param libname: Name of the library to generate as first argument (without lib or .so)
# :type libname: string
# :param INCLUDES: Include files needed for the library, absolute or relative to ${PROJECT_SOURCE_DIR}
# :type INCLUDES: list of strings
# :param SOURCES: Source files to be added. If empty, a header-only library is assumed
# :type SOURCES: list of strings
# :param DEPENDS: List of extra (non-catkin, non-mrt) dependencies. This should only be required for including external projects.
# :type DEPENDS: list of strings
# :param LIBRARIES: Extra (non-catkin, non-mrt) libraries to link to. This should only be required for external projects
# :type LIBRARIES: list of strings
#
# Example:
# ::
#
#   mrt_add_library( example_package
#       INCLUDES include/example_package/myclass.h include/example_package/myclass2.h
#       SOURCES src/myclass.cpp src/myclass.cpp
#       )
#
# @@public
#
function(mrt_add_library libname)
    set(LIBRARY_NAME ${libname})
    if(NOT LIBRARY_NAME)
        message(FATAL_ERROR "No executable name specified for call to mrt_add_library!")
    endif()
    cmake_parse_arguments(MRT_ADD_LIBRARY "" "" "INCLUDES;SOURCES;DEPENDS;LIBRARIES" ${ARGN})
    set(LIBRARY_TARGET_NAME ${LIBRARY_NAME})

    if(NOT MRT_ADD_LIBRARY_INCLUDES AND NOT MRT_ADD_LIBRARY_SOURCES)
        return()
    endif()

    # catch header-only libraries
    if(NOT MRT_ADD_LIBRARY_SOURCES)
        # we only set a fake target to make the files show up in IDEs
        message(STATUS "Adding header-only library with files ${MRT_ADD_LIBRARY_INCLUDES}")
        add_custom_target(${LIBRARY_TARGET_NAME} SOURCES ${MRT_ADD_LIBRARY_INCLUDES})
        return()
    endif()

    foreach(SOURCE_FILE ${MRT_ADD_LIBRARY_SOURCES})
        get_filename_component(FILE_EXT ${SOURCE_FILE} EXT)
        if ("${FILE_EXT}" STREQUAL ".cu")
            list(APPEND _MRT_CUDA_SOURCES_FILES "${SOURCE_FILE}")
            set(_MRT_HAS_CUDA_SOURCE_FILES TRUE)
        else()
            list(APPEND _MRT_CPP_SOURCE_FILES "${SOURCE_FILE}")
            set(_MRT_HAS_CPP_SOURCE_FILES TRUE)
        endif()
    endforeach()

    # This is the easiest for a CUDA only library: Create an empty file.
    if(NOT _MRT_HAS_CPP_SOURCE_FILES)
        message(STATUS "CMAKE_CURRENT_BINARY_DIR: ${CMAKE_CURRENT_BINARY_DIR}")
        file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/empty.cpp" "")
        list(APPEND _MRT_CPP_SOURCE_FILES "${CMAKE_CURRENT_BINARY_DIR}/empty.cpp")
    endif()

    # generate the target
    message(STATUS "Adding library \"${LIBRARY_NAME}\" with source ${_MRT_CPP_SOURCE_FILES}")
    add_library(${LIBRARY_TARGET_NAME}
        ${MRT_ADD_LIBRARY_INCLUDES} ${_MRT_CPP_SOURCE_FILES}
        )
    set_target_properties(${LIBRARY_TARGET_NAME}
        PROPERTIES OUTPUT_NAME ${LIBRARY_NAME}
        )
    target_compile_options(${LIBRARY_TARGET_NAME}
        PRIVATE ${MRT_SANITIZER_CXX_FLAGS}
        )
    set(_combined_deps ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${MRT_ADD_LIBRARY_DEPENDS})
    if(_combined_deps)
        add_dependencies(${LIBRARY_TARGET_NAME} ${_combined_deps})
    endif()
    target_link_libraries(${LIBRARY_TARGET_NAME}
        ${catkin_LIBRARIES}
        ${mrt_LIBRARIES}
        ${MRT_ADD_LIBRARY_LIBRARIES}
        ${MRT_SANITIZER_CXX_FLAGS}
        ${MRT_SANITIZER_LINK_FLAGS}
        )
    # add dependency to python_api if existing (needs to be declared before this library)
    foreach(_py_api_target ${${PROJECT_NAME}_PYTHON_API_TARGET})
        target_link_libraries(${_py_api_target} PRIVATE ${LIBRARY_TARGET_NAME})
    endforeach()

    # Add cuda target
    if (_MRT_HAS_CUDA_SOURCE_FILES)
        if (NOT DEFINED CUDA_FOUND)
            message(FATAL_ERROR "Found CUDA source file but no dependency to CUDA. Please add <depend>cuda</depend> to your package.xml.")
        endif()

        # generate cuda target
        set(CUDA_TARGET_NAME _${LIBRARY_TARGET_NAME}_cuda)
        # NVCC does not like '-' in file names.
        string(REPLACE "-" "_" CUDA_TARGET_NAME ${CUDA_TARGET_NAME})

        message(STATUS "Adding library \"${CUDA_TARGET_NAME}\" with source ${_MRT_CUDA_SOURCES_FILES}")

        if(${CMAKE_VERSION} VERSION_LESS "3.9.0")
            cuda_add_library(${CUDA_TARGET_NAME} SHARED ${_MRT_CUDA_SOURCES_FILES})
        else()
            add_library(${CUDA_TARGET_NAME} SHARED ${_MRT_CUDA_SOURCES_FILES})
            # We cannot link to all libraries as nvcc does not unterstand all the flags
            # etc. which could be passed to target_link_libraries as a target. So the
            # dependencies were added to the mrt_CUDA_LIBRARIES variable.
            target_link_libraries(${CUDA_TARGET_NAME} PRIVATE ${mrt_CUDA_LIBRARIES})
            set_property(TARGET ${CUDA_TARGET_NAME} PROPERTY POSITION_INDEPENDENT_CODE ON)
            set_property(TARGET ${CUDA_TARGET_NAME} PROPERTY CUDA_SEPARABLE_COMPILATION ON)
        endif()

        # link cuda library to executable
        target_link_libraries(${LIBRARY_TARGET_NAME} ${CUDA_TARGET_NAME})
    endif()

    # append to list of all targets in this project
    set(${PROJECT_NAME}_GENERATED_LIBRARIES ${${PROJECT_NAME}_GENERATED_LIBRARIES} ${LIBRARY_TARGET_NAME} ${CUDA_TARGET_NAME} PARENT_SCOPE)
    set(${PROJECT_NAME}_MRT_TARGETS ${${PROJECT_NAME}_MRT_TARGETS} ${LIBRARY_TARGET_NAME} ${CUDA_TARGET_NAME} PARENT_SCOPE)
endfunction()


#
# Adds an executable.
#
# This command ensures the executable is compiled with all necessary dependencies.
#
# .. note:: Make sure to call this after all messages and parameter generation CMAKE-Commands so that all dependencies are visible.
#
# The files are automatically added to the list of installable targets so that ``mrt_install`` can mark them for installation.
#
# :param execname: name of the executable
# :type execname: string
# :param FOLDER: Folder containing the .cpp/.cc-files and .h/.hh/.hpp files for the executable, relative to ``${PROJECT_SOURCE_DIR}``.
# :type FOLDER: string
# :param FILES: List of extra source files to add. This or the FOLDER parameter is mandatory.
# :type FILES: list of strings
# :param DEPENDS: List of extra (non-catkin, non-mrt) dependencies. This should only be required for including external projects.
# :type DEPENDS: list of strings
# :param LIBRARIES: Extra (non-catkin, non-mrt) libraries to link to. This should only be required for external projects
# :type LIBRARIES: list of strings
#
# Example:
# ::
#
#   mrt_add_executable( example_package
#       FOLDER src/example_package
#       )
#
# @@public
#
function(mrt_add_executable execname)
    set(EXEC_NAME ${execname})
    if(NOT EXEC_NAME)
        message(FATAL_ERROR "No executable name specified for call to mrt_add_executable()!")
    endif()
    cmake_parse_arguments(MRT_ADD_EXECUTABLE "" "FOLDER" "FILES;DEPENDS;LIBRARIES" ${ARGN})
    if(NOT MRT_ADD_EXECUTABLE_FOLDER AND NOT MRT_ADD_EXECUTABLE_FILES)
        message(FATAL_ERROR "No FOLDER or FILES argument passed to mrt_add_executable()!")
    endif()
    set(EXEC_TARGET_NAME ${PROJECT_NAME}-${EXEC_NAME}-exec)

    # get the files
    if(MRT_ADD_EXECUTABLE_FOLDER)
        mrt_glob_files_recurse(EXEC_SOURCE_FILES_INC "${MRT_ADD_EXECUTABLE_FOLDER}/*.h" "${MRT_ADD_EXECUTABLE_FOLDER}/*.hpp" "${MRT_ADD_EXECUTABLE_FOLDER}/*.hh" "${MRT_ADD_EXECUTABLE_FOLDER}/*.cuh")
        mrt_glob_files_recurse(EXEC_SOURCE_FILES_SRC "${MRT_ADD_EXECUTABLE_FOLDER}/*.cpp" "${MRT_ADD_EXECUTABLE_FOLDER}/*.cc" "${MRT_ADD_EXECUTABLE_FOLDER}/*.cu")
    endif()
    if(MRT_ADD_EXECUTABLE_FILES)
        list(APPEND EXEC_SOURCE_FILES_SRC ${MRT_ADD_EXECUTABLE_FILES})
        list(REMOVE_DUPLICATES EXEC_SOURCE_FILES_SRC)
    endif()
    if(NOT EXEC_SOURCE_FILES_SRC)
        return()
    endif()

    # separate cuda files
    set(_MRT_CPP_SOURCE_FILES )
    set(_MRT_CUDA_SOURCES_FILES )
    foreach(SOURCE_FILE ${EXEC_SOURCE_FILES_SRC})
        get_filename_component(FILE_EXT ${SOURCE_FILE} EXT)
        if ("${FILE_EXT}" STREQUAL ".cu")
            list(APPEND _MRT_CUDA_SOURCES_FILES "${SOURCE_FILE}")
            set(_MRT_HAS_CUDA_SOURCE_FILES TRUE)
        else()
            list(APPEND _MRT_CPP_SOURCE_FILES "${SOURCE_FILE}")
        endif()
    endforeach()

    # generate the target
    message(STATUS "Adding executable \"${EXEC_NAME}\"")
    add_executable(${EXEC_TARGET_NAME}
        ${EXEC_SOURCE_FILES_INC}
        ${_MRT_CPP_SOURCE_FILES}
        )
    set_target_properties(${EXEC_TARGET_NAME}
        PROPERTIES OUTPUT_NAME ${EXEC_NAME}
        )
    target_compile_options(${EXEC_TARGET_NAME}
        PRIVATE ${MRT_SANITIZER_CXX_FLAGS}
        )
    target_include_directories(${EXEC_TARGET_NAME}
        PRIVATE "${MRT_ADD_EXECUTABLE_FOLDER}"
        )
    set(_combined_deps ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${MRT_ADD_EXECUTABLE_DEPENDS})
    if(_combined_deps)
        add_dependencies(${EXEC_TARGET_NAME} ${_combined_deps})
    endif()
    target_link_libraries(${EXEC_TARGET_NAME} PRIVATE
        ${catkin_LIBRARIES}
        ${mrt_LIBRARIES}
        ${MRT_ADD_EXECUTABLE_LIBRARIES}
        ${MRT_SANITIZER_EXE_CXX_FLAGS}
        ${MRT_SANITIZER_LINK_FLAGS}
        ${${PROJECT_NAME}_GENERATED_LIBRARIES}
        )

    # Add cuda target
    if (_MRT_HAS_CUDA_SOURCE_FILES)
        if (NOT DEFINED CUDA_FOUND)
            message(FATAL_ERROR "Found CUDA source file but no dependency to CUDA. Please add <depend>CUDA</depend> to your package.xml.")
        endif()

        # generate cuda target
        set(CUDA_TARGET_NAME _${EXEC_TARGET_NAME}_cuda)

        # NVCC does not like '-' in file names and because 'cuda_add_library' creates
        # a helper file which contains the target name, one has to replace '-'.
        string(REPLACE "-" "_" CUDA_TARGET_NAME ${CUDA_TARGET_NAME})

        if(${CMAKE_VERSION} VERSION_LESS "3.9.0")
            cuda_add_library(${CUDA_TARGET_NAME} STATIC ${_MRT_CUDA_SOURCES_FILES})
        else()
            message(STATUS "Adding ${_MRT_CUDA_SOURCES_FILES} files.")
            add_library(${CUDA_TARGET_NAME} SHARED ${_MRT_CUDA_SOURCES_FILES})
            # We cannot link to all libraries as nvcc does not unterstand all the flags
            # etc. which could be passed to target_link_libraries as a target. So the
            # dependencies were added to the mrt_CUDA_LIBRARIES variable.
            target_link_libraries(${CUDA_TARGET_NAME} PRIVATE ${mrt_CUDA_LIBRARIES})
            set_property(TARGET ${CUDA_TARGET_NAME} PROPERTY POSITION_INDEPENDENT_CODE ON)
            set_property(TARGET ${CUDA_TARGET_NAME} PROPERTY CUDA_SEPARABLE_COMPILATION ON)
        endif()

        # link cuda library to executable
        target_link_libraries(${EXEC_TARGET_NAME} PRIVATE ${CUDA_TARGET_NAME})
    endif()

    # append to list of all targets in this project
    set(${PROJECT_NAME}_MRT_TARGETS ${${PROJECT_NAME}_MRT_TARGETS} ${EXEC_TARGET_NAME} ${CUDA_TARGET_NAME} PARENT_SCOPE)
endfunction()


#
# Adds a nodelet.
#
# This command ensures the nodelet is compiled with all necessary dependencies. Make sure to add lib{NAME}_nodelet to the ``nodelet_plugins.xml`` file.
#
# .. note:: Make sure to call this after all messages and parameter generation CMAKE-Commands so that all dependencies are visible.
#
# The files are automatically added to the list of installable targets so that ``mrt_install`` can mark them for installation.
#
# It requires a ``*_nodelet.cpp``-File to be present in this folder.
# The command will look for a ``*_node.cpp``-file and remove it from the list of files to avoid ``main()``-functions to be compiled into the library.
#
# :param nodeletname: base name of the nodelet (_nodelet will be appended to the base name to avoid conflicts with library packages)
# :type nodeletname: string
# :param FOLDER: Folder with cpp files for the executable, relative to ``${PROJECT_SOURCE_DIR}``
# :type FOLDER: string
# :param DEPENDS: List of extra (non-catkin, non-mrt) CMAKE dependencies. This should only be required for including external projects.
# :type DEPENDS: list of strings
# :param LIBRARIES: Extra (non-catkin, non-mrt) libraries to link to. This should only be required for external projects
# :type LIBRARIES: list of strings
# :param TARGETNAME: Choose the name of the internal CMAKE target. Will be autogenerated if not specified.
# :type TARGETNAME: string
#
# Example:
# ::
#
#   mrt_add_nodelet( example_package
#       FOLDER src/example_package
#       )
#
# The resulting entry in the ``nodelet_plugins.xml`` is thus: <library path="lib/libexample_package_nodelet">
#
# @@public
#
function(mrt_add_nodelet nodeletname)

    set(NODELET_NAME ${nodeletname})
    if(NOT NODELET_NAME)
        message(FATAL_ERROR "No nodelet name specified for call to mrt_add_nodelet()!")
    endif()
    cmake_parse_arguments(MRT_ADD_NODELET "" "FOLDER;TARGETNAME" "DEPENDS;LIBRARIES" ${ARGN})
    if(NOT MRT_ADD_NODELET_TARGETNAME)
        set(NODELET_TARGET_NAME ${PROJECT_NAME}-${NODELET_NAME}-nodelet)
    else()
        set(NODELET_TARGET_NAME ${MRT_ADD_NODELET_TARGETNAME})
    endif()

    # get the files
    mrt_glob_files(NODELET_SOURCE_FILES_INC "${MRT_ADD_NODELET_FOLDER}/*.h" "${MRT_ADD_NODELET_FOLDER}/*.hpp" "${MRT_ADD_EXECUTABLE_FOLDER}/*.hh")
    mrt_glob_files(NODELET_SOURCE_FILES_SRC "${MRT_ADD_NODELET_FOLDER}/*.cpp" "${MRT_ADD_EXECUTABLE_FOLDER}/*.cc")

    # Find nodelet
    mrt_glob_files(NODELET_CPP "${MRT_ADD_NODELET_FOLDER}/*_nodelet.cpp" "${MRT_ADD_NODELET_FOLDER}/*_nodelet.cc")
    if(NOT NODELET_CPP)
        return()
    endif()

    # Remove nodes (with their main) from src-files
    mrt_glob_files(NODE_CPP "${MRT_ADD_NODELET_FOLDER}/*_node.cpp" "${MRT_ADD_NODELET_FOLDER}/*_node.cc")
    if (NODE_CPP)
        list(REMOVE_ITEM NODELET_SOURCE_FILES_SRC ${NODE_CPP})
    endif ()

    # determine library name
    STRING(REGEX REPLACE "_node" "" NODELET_NAME ${NODELET_NAME})
    STRING(REGEX REPLACE "_nodelet" "" NODELET_NAME ${NODELET_NAME})
    set(NODELET_NAME ${NODELET_NAME}_nodelet)

    # generate the target
    message(STATUS "Adding nodelet \"${NODELET_NAME}\"")
    add_library(${NODELET_TARGET_NAME}
        ${NODELET_SOURCE_FILES_INC}
        ${NODELET_SOURCE_FILES_SRC}
        )
    set_target_properties(${NODELET_TARGET_NAME}
        PROPERTIES OUTPUT_NAME ${NODELET_NAME}
        )
    target_compile_options(${NODELET_TARGET_NAME}
        PRIVATE ${MRT_SANITIZER_CXX_FLAGS}
        )
    add_dependencies(${NODELET_TARGET_NAME} ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${MRT_ADD_NODELET_DEPENDS})
    target_link_libraries(${NODELET_TARGET_NAME}
        ${catkin_LIBRARIES}
        ${mrt_LIBRARIES}
        ${MRT_ADD_NODELET_LIBRARIES}
        ${MRT_SANITIZER_CXX_FLAGS}
        ${MRT_SANITIZER_LINK_FLAGS}
        )
    # append to list of all targets in this project
    set(${PROJECT_NAME}_GENERATED_LIBRARIES ${${PROJECT_NAME}_GENERATED_LIBRARIES} ${NODELET_TARGET_NAME} PARENT_SCOPE)
    set(${PROJECT_NAME}_MRT_TARGETS ${${PROJECT_NAME}_MRT_TARGETS} ${NODELET_TARGET_NAME} PARENT_SCOPE)
endfunction()


#
# Adds a node and a corresponding nodelet.
#
# This command ensures the node/nodelet are compiled with all necessary dependencies. Make sure to add lib{NAME}_nodelet to the ``nodelet_plugins.xml`` file.
#
# .. note:: Make sure to call this after all messages and parameter generation CMAKE-Commands so that all dependencies are visible.
#
# The files are automatically added to the list of installable targets so that ``mrt_install`` can mark them for installation.
#
# It requires a ``*_nodelet.cpp`` file and a ``*_node.cpp`` file to be present in this folder. It will then compile a nodelet-library, create an executable from the ``*_node.cpp`` file and link the executable with the nodelet library.
#
# Unless the variable ``${MRT_NO_FAIL_ON_TESTS}`` is set, failing unittests will result in a failed build.
#
# :param basename: base name of the node/nodelet (_nodelet will be appended for the nodelet name to avoid conflicts with library packages)
# :type basename: string
# :param FOLDER: Folder with cpp files for the executable, relative to ``${PROJECT_SOURCE_DIR}``
# :type FOLDER: string
# :param DEPENDS: List of extra (non-catkin, non-mrt) CMAKE dependencies. This should only be required for including external projects.
# :type DEPENDS: list of strings
# :param LIBRARIES: Extra (non-catkin, non-mrt) libraries to link to. This should only be required for external projects
# :type LIBRARIES: list of strings
#
# Example:
# ::
#
#   mrt_add_node_and_nodelet( example_package
#       FOLDER src/example_package
#       )
#
# The resulting entry in the ``nodelet_plugins.xml`` is thus: <library path="lib/libexample_package_nodelet">
#
# @@public
#
function(mrt_add_node_and_nodelet basename)
    cmake_parse_arguments(MRT_ADD_NN "" "FOLDER" "DEPENDS;LIBRARIES" ${ARGN})
    set(BASE_NAME ${basename})
    if(NOT BASE_NAME)
        message(FATAL_ERROR "No base name specified for call to mrt_add_node_and_nodelet()!")
    endif()
    set(NODELET_TARGET_NAME ${PROJECT_NAME}-${BASE_NAME}-nodelet)

    # add nodelet
    mrt_add_nodelet(${BASE_NAME}
        FOLDER ${MRT_ADD_NN_FOLDER}
        TARGETNAME ${NODELET_TARGET_NAME}
        DEPENDS ${MRT_ADD_NN_DEPENDS}
        LIBRARIES ${MRT_ADD_NN_LIBRARIES}
        )
    # pass lists on to parent scope
    set(${PROJECT_NAME}_GENERATED_LIBRARIES ${${PROJECT_NAME}_GENERATED_LIBRARIES} PARENT_SCOPE)
    set(${PROJECT_NAME}_MRT_TARGETS ${${PROJECT_NAME}_MRT_TARGETS} PARENT_SCOPE)

    # search the files we have to build with
    if(NOT TARGET ${NODELET_TARGET_NAME} OR DEFINED MRT_SANITIZER_ENABLED)
        unset(NODELET_TARGET_NAME)
        mrt_glob_files(NODE_CPP "${MRT_ADD_NN_FOLDER}/*.cpp" "${MRT_ADD_NN_FOLDER}/*.cc")
    else()
        mrt_glob_files(NODE_CPP "${MRT_ADD_NN_FOLDER}/*_node.cpp" "${MRT_ADD_NN_FOLDER}/*_node.cc")
    endif()

    # find *_node file containing the main() and add the executable
    mrt_glob_files(NODE_H "${MRT_ADD_NN_FOLDER}/*.h" "${MRT_ADD_NN_FOLDER}/*.hpp" "${MRT_ADD_NN_FOLDER}/*.hh")
    mrt_glob_files(NODE_MAIN "${MRT_ADD_NN_FOLDER}/*_node.cpp" "${MRT_ADD_NN_FOLDER}/*_node.cc")
    if(NODE_MAIN)
        mrt_add_executable(${BASE_NAME}
            FILES ${NODE_CPP} ${NODE_H}
            DEPENDS ${MRT_ADD_NN_DEPENDS} ${NODELET_TARGET_NAME}
            LIBRARIES ${MRT_ADD_NN_LIBRARIES} ${NODELET_TARGET_NAME}
            )
        # pass lists on to parent scope
        set(${PROJECT_NAME}_GENERATED_LIBRARIES ${${PROJECT_NAME}_GENERATED_LIBRARIES} PARENT_SCOPE)
        set(${PROJECT_NAME}_MRT_TARGETS ${${PROJECT_NAME}_MRT_TARGETS} PARENT_SCOPE)
    endif()
endfunction()


#
# Adds all rostests (identified by a .test file) contained in a folder as unittests.
#
# If a .cpp file exists with the same name, it will be added and comiled as a gtest test.
# Unittests can be run with "catkin run_tests" or similar. "-test" will be appended to the name of the test node to avoid conflicts (i.e. the type argument should then be <test ... type="mytest-test"/> in a mytest.test file).
#
# Unittests will always be executed with the folder as cwd. E.g. if the test folder contains a sub-folder "test_data", it can simply be accessed as "test_data".
#
# If coverage information is enabled (by setting ``MRT_ENABLE_COVARAGE`` to true), coverage analysis will be performed after unittests have run. The results can be found in the package's build folder in the folder "coverage".
#
# Unless the variable ``${MRT_NO_FAIL_ON_TESTS}`` is set, failing unittests will result in a failed build.
#
# :param folder: folder containing the tests (relative to ``${PROJECT_SOURCE_DIR}``) as first argument
# :type folder: string
# :param LIBRARIES: Additional (non-catkin, non-mrt) libraries to link to
# :type LIBRARIES: list of strings
# :param DEPENDS: Additional (non-catkin, non-mrt) dependencies (e.g. with catkin_download_test_data)
# :type DEPENDS: list of strings
#
# Example:
# ::
#
#   mrt_add_ros_tests( test
#       )
#
# @@public
#
function(mrt_add_ros_tests folder)
    set(TEST_FOLDER ${folder})
    cmake_parse_arguments(MRT_ADD_ROS_TESTS "" "" "LIBRARIES;DEPENDS" ${ARGN})
    mrt_glob_files(_ros_tests "${TEST_FOLDER}/*.test")
    add_custom_target(${PROJECT_NAME}-rostest_test_files SOURCES ${_ros_tests})
    configure_file(${MCM_ROOT}/cmake/Templates/test_utility.hpp.in ${PROJECT_BINARY_DIR}/tests/test/test_utility.hpp @@ONLY)

    foreach(_ros_test ${_ros_tests})
        get_filename_component(_test_name ${_ros_test} NAME_WE)
        # make sure we add only one -test to the target
        STRING(REGEX REPLACE "-test" "" TEST_NAME ${_test_name})
        set(TEST_NAME ${TEST_NAME}-test)
        set(TEST_TARGET_NAME ${PROJECT_NAME}-${TEST_NAME})
        # look for a matching .cpp
        if(EXISTS "${PROJECT_SOURCE_DIR}/${TEST_FOLDER}/${_test_name}.cpp")
            message(STATUS "Adding gtest-rostest \"${TEST_TARGET_NAME}\" with test file ${_ros_test}")
            add_rostest_gtest(${TEST_TARGET_NAME} ${_ros_test} "${TEST_FOLDER}/${_test_name}.cpp")
            target_compile_options(${TEST_TARGET_NAME}
                PRIVATE ${MRT_SANITIZER_EXE_CXX_FLAGS}
                )
            target_link_libraries(${TEST_TARGET_NAME}
                ${${PROJECT_NAME}_GENERATED_LIBRARIES}
                ${catkin_LIBRARIES}
                ${mrt_TEST_LIBRARIES}
                ${MRT_ADD_ROS_TESTS_LIBRARIES}
                ${MRT_SANITIZER_EXE_CXX_FLAGS}
                ${MRT_SANITIZER_LINK_FLAGS}
                gtest_main
                )
            target_include_directories(${TEST_TARGET_NAME}
                PRIVATE ${PROJECT_BINARY_DIR}/tests)
            add_dependencies(${TEST_TARGET_NAME}
                ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${${PROJECT_NAME}_MRT_TARGETS} ${MRT_ADD_ROS_TESTS_DEPENDS}
                )
            set_target_properties(${TEST_TARGET_NAME} PROPERTIES OUTPUT_NAME ${TEST_NAME})
            set(TARGET_ADDED True)
        else()
            message(STATUS "Adding plain rostest \"${_ros_test}\"")
            add_rostest(${_ros_test}
                DEPENDENCIES ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${${PROJECT_NAME}_MRT_TARGETS} ${MRT_ADD_ROS_TESTS_DEPENDS}
                )
        endif()
    endforeach()
    if(MRT_ENABLE_COVERAGE AND TARGET_ADDED AND NOT TARGET ${PROJECT_NAME}-coverage AND TARGET run_tests)
        _setup_coverage_info()
    endif()
    _mrt_register_test()
endfunction()

#
# Adds all gtests (without a corresponding .test file) contained in a folder as unittests.
#
# :param folder: folder containing the tests (relative to ``${PROJECT_SOURCE_DIR}``) as first argument
# :type folder: string
# :param LIBRARIES: Additional (non-catkin, non-mrt) libraries to link to
# :type LIBRARIES: list of strings
# :param DEPENDS: Additional (non-catkin, non-mrt) dependencies (e.g. with catkin_download_test_data)
# :type DEPENDS: list of strings
#
#
# Unittests will be executed with the folder as cwd if ctest or the run_test target is used. E.g. if the test folder contains a sub-folder "test_data", it can simply be accessed as "test_data".
# Another way of getting the location of the project root folder path is to ``#include "test/test_utility.hpp"`` and use the variable ``<project_name>::test::projectRootDir``.
#
# Unless the variable ``${MRT_NO_FAIL_ON_TESTS}`` is set, failing unittests will result in a failed build.
#
# If coverage information is enabled (by setting ``MRT_ENABLE_COVARAGE`` to true), coverage analysis will be performed after unittests have run. The results can be found in the package's build folder in the folder "coverage".
#
# Example:
# ::
#
#   mrt_add_tests( test
#       )
#
# @@public
#
function(mrt_add_tests folder)
    set(TEST_FOLDER ${folder})
    cmake_parse_arguments(MRT_ADD_TESTS "" "" "LIBRARIES;DEPENDS" ${ARGN})
    mrt_glob_files(_tests "${TEST_FOLDER}/*.cpp" "${TEST_FOLDER}/*.cc")
    configure_file(${MCM_ROOT}/cmake/Templates/test_utility.hpp.in ${PROJECT_BINARY_DIR}/tests/test/test_utility.hpp @@ONLY)

    foreach(_test ${_tests})
        get_filename_component(_test_name ${_test} NAME_WE)
        # make sure we add only one -test to the target
        STRING(REGEX REPLACE "-test" "" TEST_TARGET_NAME ${_test_name})
        set(TEST_TARGET_NAME ${PROJECT_NAME}-${TEST_TARGET_NAME}-test)
        # exclude cpp files with a test file (those are ros tests)
        if(NOT EXISTS "${PROJECT_SOURCE_DIR}/${TEST_FOLDER}/${_test_name}.test")
            message(STATUS "Adding gtest unittest \"${TEST_TARGET_NAME}\" with working dir ${PROJECT_SOURCE_DIR}/${TEST_FOLDER}")
            catkin_add_gtest(${TEST_TARGET_NAME} ${_test} WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/${TEST_FOLDER})
            target_link_libraries(${TEST_TARGET_NAME}
                ${${PROJECT_NAME}_GENERATED_LIBRARIES}
                ${catkin_LIBRARIES}
                ${mrt_TEST_LIBRARIES}
                ${MRT_ADD_TESTS_LIBRARIES}
                ${MRT_SANITIZER_EXE_CXX_FLAGS}
                ${MRT_SANITIZER_LINK_FLAGS}
                gtest_main)
            target_compile_options(${TEST_TARGET_NAME}
                PRIVATE ${MRT_SANITIZER_EXE_CXX_FLAGS}
                )
            target_include_directories(${TEST_TARGET_NAME} 
                PRIVATE ${PROJECT_BINARY_DIR}/tests)

            add_dependencies(${TEST_TARGET_NAME}
                ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${${PROJECT_NAME}_MRT_TARGETS} ${MRT_ADD_TESTS_DEPENDS}
                )
            set(TARGET_ADDED True)
        endif()
    endforeach()
    if(MRT_ENABLE_COVERAGE AND TARGET_ADDED AND NOT TARGET ${PROJECT_NAME}-coverage AND TARGET run_tests)
        _setup_coverage_info()
    endif()
    _mrt_register_test()
endfunction()


# Adds python nosetest contained in a folder. Wraps the function catkin_add_nosetests.
#
# :param folder: folder containing the tests (relative to ``${PROJECT_SOURCE_DIR}``) as first argument
# :type folder: string
# :param DEPENDS: Additional (non-catkin, non-mrt) dependencies (e.g. with catkin_download_test_data)
# :type DEPENDS: list of strings
# :param DEPENDENCIES: Alias for DEPENDS
# :type DEPENDENCIES: list of strings
#
# Example:
# ::
#
#   mrt_add_nosetests(test)
#
# @@public
#
function(mrt_add_nosetests folder)
    set(TEST_FOLDER ${folder})
    cmake_parse_arguments(MRT_ADD_NOSETESTS "" "" "DEPENDS;DEPENDENCIES" ${ARGN})
    if(NOT IS_DIRECTORY ${PROJECT_SOURCE_DIR}/${TEST_FOLDER})
        return()
    endif()

    message(STATUS "Adding nosetests in folder ${TEST_FOLDER}")
    catkin_add_nosetests(${TEST_FOLDER}
        DEPENDENCIES ${MRT_ADD_NOSETESTS_DEPENDENCIES} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${${PROJECT_NAME}_PYTHON_API_TARGET}
        )
    if(MRT_ENABLE_COVERAGE AND MRT_FORCE_PYTHON_COVERAGE AND NOT TARGET ${PROJECT_NAME}-coverage AND TARGET run_tests)
        _setup_coverage_info()
    endif()
    _mrt_register_test()
endfunction()


# Installs all relevant project files.
#
# All targets added by the mrt_add_<library/executable/nodelet/...> commands will be installed automatically when using this command. Other files/folders (launchfiles, scripts) need to be specified explicitly.
# Non existing files and folders will be silently ignored. All files will be marked as project files for IDEs.
#
# :param PROGRAMS: List of all folders and files that are programs (python scripts will be indentified and treated separately). Files will be made executable.
# :type PROGRAMS: list of strings
# :param FILES: List of non-executable files and folders. Subfolders will be installed recursively.
# :type FILES: list of strings
#
# Example:
# ::
#
#   mrt_install(
#       PROGRAMS scripts
#       FILES launch nodelet_plugins.xml
#       )
#
# @@public
#
function(mrt_install)
    cmake_parse_arguments(MRT_INSTALL "" "" "PROGRAMS;FILES" ${ARGN})

    # install targets
    if(${PROJECT_NAME}_MRT_TARGETS)
        message(STATUS "Marking targets \"${${PROJECT_NAME}_MRT_TARGETS}\" of package \"${PROJECT_NAME}\" for installation")
        install(TARGETS ${${PROJECT_NAME}_MRT_TARGETS}
            ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
            LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
            RUNTIME DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
            )
    endif()

    # install header
    if(EXISTS ${PROJECT_SOURCE_DIR}/include/${PROJECT_NAME}/)
        message(STATUS "Marking HEADER FILES in \"include\" folder of package \"${PROJECT_NAME}\" for installation")
        install(DIRECTORY include/${PROJECT_NAME}/
            DESTINATION ${CATKIN_PACKAGE_INCLUDE_DESTINATION}
            PATTERN ".gitignore" EXCLUDE
            )
    endif()

    # helper function for installing programs
    function(mrt_install_program program_path)
        get_filename_component(extension ${program_path} EXT)
        get_filename_component(program ${program_path} NAME)
        if("${extension}" STREQUAL ".py")
            message(STATUS "Marking PYTHON PROGRAM \"${program}\" of package \"${PROJECT_NAME}\" for installation")
            catkin_install_python(PROGRAMS ${program_path}
                DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
                )
        else()
            message(STATUS "Marking PROGRAM \"${program}\" of package \"${PROJECT_NAME}\" for installation")
            install(PROGRAMS ${program_path}
                DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
                )
        endif()
    endfunction()

    # install programs
    foreach(ELEMENT ${MRT_INSTALL_PROGRAMS})
        if(IS_DIRECTORY ${PROJECT_SOURCE_DIR}/${ELEMENT})
            mrt_glob_files(FILES "${PROJECT_SOURCE_DIR}/${ELEMENT}/[^.]*[^~]")
            foreach(FILE ${FILES})
                if(NOT IS_DIRECTORY ${PROJECT_SOURCE_DIR}/${FILE})
                    mrt_install_program(${FILE})
                endif()
            endforeach()
        elseif(EXISTS ${PROJECT_SOURCE_DIR}/${ELEMENT})
            mrt_install_program(${ELEMENT})
        endif()
    endforeach()

    # install files
    foreach(ELEMENT ${MRT_INSTALL_FILES})
        if(IS_DIRECTORY ${PROJECT_SOURCE_DIR}/${ELEMENT})
            message(STATUS "Marking SHARED CONTENT FOLDER \"${ELEMENT}\" of package \"${PROJECT_NAME}\" for installation")
            install(DIRECTORY ${ELEMENT}
                DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
                )
        elseif(EXISTS ${PROJECT_SOURCE_DIR}/${ELEMENT})
            message(STATUS "Marking FILE \"${ELEMENT}\" of package \"${PROJECT_NAME}\" for installation")
            install(FILES ${ELEMENT} DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION})
        endif()
    endforeach()
endfunction()
