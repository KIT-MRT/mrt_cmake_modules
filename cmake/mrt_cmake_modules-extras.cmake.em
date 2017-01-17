# Generated from: mrt_cmake_modules/cmake/mrt_cmake_modules-extra.cmake.em
if(_MRT_CMAKE_MODULES_EXTRAS_INCLUDED_)
    return()
endif()
set(_MRT_CMAKE_MODULES_EXTRAS_INCLUDED_ TRUE)

# Set the cmake install path
@[if DEVELSPACE]@
# cmake dir in develspace
list(APPEND CMAKE_MODULE_PATH "@(CMAKE_CURRENT_SOURCE_DIR)/cmake/Modules")
@[else]@
# cmake dir in installspace
list(APPEND CMAKE_MODULE_PATH "@(PKG_CMAKE_DIR)/Modules")
@[end if]@
set(MCM_ROOT "@(CMAKE_CURRENT_SOURCE_DIR)")


function(mrt_python_module_setup)
    # automatically installs python modules located under src/${PROJECT_NAME} (this is a restriction by python and catkin).
    # modules can afterwards simply be included using "import <project_name>" in python
    find_package(catkin REQUIRED)
    if(ARGN)
        message(FATAL_ERROR "mrt_python_module_setup() called with unused arguments: ${ARGN}")
    endif()
    if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/src/${PROJECT_NAME}/__init__.py")
        return()
    endif()
    set(PKG_PYTHON_MODULE ${PROJECT_NAME})
    set(${PROJECT_NAME}_PYTHON_MODULE ${PROJECT_NAME} PARENT_SCOPE)
    set(PACKAGE_DIR "src")
    configure_file(${MCM_ROOT}/cmake/Templates/setup.py.in "${CMAKE_CURRENT_LIST_DIR}/setup.py" @@ONLY)
    catkin_python_setup()
endfunction()


function(mrt_add_python_api)
    # adds a python module from boost-python cpp files. The name of the module needs to be passed as first parameter.
    # FILES: cpp Files with the boost python code for the module
    # The function defines PYTHON_API_MODULE_NAME with the genereated library name for use in the cpp files
    # The module can then simply be included using "import <modulename>"
    cmake_parse_arguments(MRT_ADD_PYTHON_API "" "" "FILES" ${ARGN})
    if(NOT MRT_ADD_PYTHON_API_FILES)
        return()
    endif()

    #set and check target name
    set( PYTHON_API_MODULE_NAME ${ARGV0})
    set( TARGET_NAME "${PROJECT_NAME}-${PYTHON_API_MODULE_NAME}-pyapi")
    set( LIBRARY_NAME "${PYTHON_API_MODULE_NAME}_pyapi")
    if("${${PROJECT_NAME}_PYTHON_MODULE}" STREQUAL "${PYTHON_API_MODULE_NAME}")
        message(FATAL_ERROR "The name of the python_api module conflicts with the name of the python module. Please choose a different name")
    endif()
    
    if("${PYTHON_API_MODULE_NAME}" STREQUAL "${PROJECT_NAME}")
        # mark that catkin_python_setup() was called and the setup.py file contains a package with the same name as the current project
        # in order to disable installation of generated __init__.py files in generate_messages() and generate_dynamic_reconfigure_options()
        set(${PROJECT_NAME}_CATKIN_PYTHON_SETUP_HAS_PACKAGE_INIT TRUE PARENT_SCOPE)
    endif()
    if(${PACKAGE_NAME}_PYTHON_API_TARGET)
        message(FATAL_ERROR "mrt_add_python_api() was already called for this project. You can add only one python_api per project!")
    endif()

    # find pythonLibs
    find_package(BoostPython REQUIRED)
    find_package(PythonLibs 2.7 REQUIRED)
    include_directories(${PYTHON_INCLUDE_DIRS})

    # add library as target
    message(STATUS "Adding python api library \"${LIBRARY_NAME}\" as python module \"${PYTHON_API_MODULE_NAME}\"")
    add_library( ${TARGET_NAME}
        ${MRT_ADD_PYTHON_API_FILES}
        )
    target_compile_definitions(${TARGET_NAME} PRIVATE -DPYTHON_API_MODULE_NAME=lib${LIBRARY_NAME})
    set_target_properties(${TARGET_NAME}
        PROPERTIES OUTPUT_NAME ${LIBRARY_NAME}
        )
    target_link_libraries( ${TARGET_NAME}
        ${PYTHON_LIBRARY}
        ${BoostPython_LIBRARIES}
        ${catkin_LIBRARIES}
        ${mrt_LIBRARIES}
        )
    add_dependencies(${TARGET_NAME} ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS})

    # append to list of all targets in this project
    set(${PACKAGE_NAME}_MRT_TARGETS ${${PACKAGE_NAME}_MRT_TARGETS} ${TARGET_NAME} PARENT_SCOPE)
    set(${PACKAGE_NAME}_PYTHON_API_TARGET ${TARGET_NAME} PARENT_SCOPE)
    # put in devel folder
    set(PREFIX  ${CATKIN_DEVEL_PREFIX})
    set(PYTHON_MODULE_DIR ${PREFIX}/${CATKIN_GLOBAL_PYTHON_DESTINATION}/${PYTHON_API_MODULE_NAME})
    add_custom_command(TARGET ${TARGET_NAME}
        POST_BUILD
        COMMAND mkdir -p ${PYTHON_MODULE_DIR} && cp -v $<TARGET_FILE:${TARGET_NAME}> ${PYTHON_MODULE_DIR}/$<TARGET_FILE_NAME:${TARGET_NAME}> && echo "from lib${LIBRARY_NAME} import *" > ${PYTHON_MODULE_DIR}/__init__.py
        WORKING_DIRECTORY ${PREFIX}
        COMMENT "Copying library files to python directory"
        )
    # configure setup.py for install
    set(PKG_PYTHON_MODULE ${PYTHON_API_MODULE_NAME})
    set(PACKAGE_DIR ${PREFIX}/${CATKIN_GLOBAL_PYTHON_DESTINATION})
    set(PACKAGE_DATA "*.so*")
    configure_file(${MCM_ROOT}/cmake/Templates/setup.py.in "${CMAKE_CURRENT_BINARY_DIR}/setup.py" @@ONLY)
    configure_file(${MCM_ROOT}/cmake/Templates/python_api_install.sh.in "${CMAKE_CURRENT_BINARY_DIR}/python_api_install.sh" @@ONLY)
    install(CODE "execute_process(COMMAND ${CMAKE_CURRENT_BINARY_DIR}/python_api_install.sh)")
endfunction()

function(mrt_add_library)
    # Adds an executable. First argument is the name of the library.
    # INCLUDES: Include files needed for the library
    # SOURCES: Source files to be added. If empty, a header-only library is assumed
    # DEPENDS: List of extra (non-catkin, non-mrt) dependencies
    # LIBRARIES: Extra (non-catkin, non-mrt) libraries to link to
    set(LIBRARY_NAME ${ARGV0})
    if(NOT LIBRARY_NAME)
        message(FATAL_ERROR "No executable name specified for call to mrt_add_library!")
    endif()
    cmake_parse_arguments(MRT_ADD_LIBRARY "" "" "INCLUDES;SOURCES;DEPENDS;LIBRARIES" ${ARGN})
    set(LIBRARY_TARGET_NAME ${PROJECT_NAME}-${LIBRARY_NAME}-lib)

    if(NOT MRT_ADD_LIBRARY_INCLUDES AND NOT MRT_ADD_LIBRARY_SOURCES)
        message(STATUS "No library files passed. Nothing to do")
        return()
    endif()

    # catch header-only libraries
    if(NOT MRT_ADD_LIBRARY_SOURCES)
        # we only set a fake target to make the files show up in IDEs
        message(STATUS "Adding header-only library with files ${MRT_ADD_LIBRARY_INCLUDES}")
        add_custom_target(${LIBRARY_TARGET_NAME} SOURCES ${MRT_ADD_LIBRARY_INCLUDES})
        return()
        message(STATUS "THIS SHOULD NEVER EXECUTE ${MRT_ADD_LIBRARY_INCLUDES}")
    endif()

    # generate the target
    message(STATUS "Adding library \"${LIBRARY_NAME}\" with source ${MRT_ADD_LIBRARY_SOURCES}")
    add_library(${LIBRARY_TARGET_NAME}
        ${MRT_ADD_LIBRARY_INCLUDES} ${MRT_ADD_LIBRARY_SOURCES}
        )
    set_target_properties(${LIBRARY_TARGET_NAME}
        PROPERTIES OUTPUT_NAME ${LIBRARY_NAME}
        )
    add_dependencies(${LIBRARY_TARGET_NAME} ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${MRT_ADD_LIBRARY_DEPENDS})
    target_link_libraries(${LIBRARY_TARGET_NAME}
        ${catkin_LIBRARIES}
        ${mrt_LIBRARIES}
        ${MRT_ADD_LIBRARY_LIBRARIES}
        )
    # add dependency to python_api if existing (needs to be declared before this library)
    if(${PACKAGE_NAME}_PYTHON_API_TARGET)
        target_link_libraries(${${PACKAGE_NAME}_PYTHON_API_TARGET} ${LIBRARY_TARGET_NAME})
    endif()
    
    # append to list of all targets in this project
    set(${PACKAGE_NAME}_LIBRARIES ${${PACKAGE_NAME}_LIBRARIES} ${LIBRARY_TARGET_NAME} PARENT_SCOPE)
    set(${PACKAGE_NAME}_MRT_TARGETS ${${PACKAGE_NAME}_MRT_TARGETS} ${LIBRARY_TARGET_NAME} PARENT_SCOPE)
endfunction()

function(mrt_add_executable)
    # Adds an executable. First argument is the name of the executable.
    # FOLDER: Folder with cpp files for the executable
    # DEPENDS: List of extra (non-catkin, non-mrt) dependencies
    # LIBRARIES: Extra (non-catkin, non-mrt) libraries to link to
    set(EXEC_NAME ${ARGV0})
    if(NOT EXEC_NAME)
        message(FATAL_ERROR "No executable name specified for call to mrt_add_executable()!")
    endif()
    cmake_parse_arguments(MRT_ADD_EXECUTABLE "" "FOLDER" "DEPENDS;LIBRARIES" ${ARGN})
    if(NOT MRT_ADD_EXECUTABLE_FOLDER)
        message(FATAL_ERROR "No FOLDER argument passed to mrt_add_executable()!")
    endif()
    set(EXEC_TARGET_NAME ${PROJECT_NAME}-${EXEC_NAME}-exec)

    # get the files
    file(GLOB EXEC_SOURCE_FILES_INC RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${MRT_ADD_EXECUTABLE_FOLDER}/*.h" "${MRT_ADD_EXECUTABLE_FOLDER}/*.hpp" "${MRT_ADD_EXECUTABLE_FOLDER}/*.hh")
    file(GLOB EXEC_SOURCE_FILES_SRC RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${MRT_ADD_EXECUTABLE_FOLDER}/*.cpp" "${MRT_ADD_EXECUTABLE_FOLDER}/*.cc")

    if(NOT EXEC_SOURCE_FILES_SRC)
        return()
    endif()

    # generate the target
    message(STATUS "Adding executable \"${EXEC_NAME}\"")
    add_executable(${EXEC_TARGET_NAME}
        ${EXEC_SOURCE_FILES_INC}
        ${EXEC_SOURCE_FILES_SRC}
        )
    set_target_properties(${EXEC_TARGET_NAME}
        PROPERTIES OUTPUT_NAME ${EXEC_NAME}
        )
    add_dependencies(${EXEC_TARGET_NAME} ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${MRT_ADD_EXECUTABLE_DEPENDS})
    target_link_libraries(${EXEC_TARGET_NAME}
        ${catkin_LIBRARIES}
        ${mrt_LIBRARIES}
        ${MRT_ADD_EXECUTABLE_LIBRARIES}
        )
    # append to list of all targets in this project
    set(${PACKAGE_NAME}_MRT_TARGETS ${${PACKAGE_NAME}_MRT_TARGETS} ${EXEC_TARGET_NAME} PARENT_SCOPE)
endfunction()

function(mrt_add_nodelet)
    # Adds an nodelet. First argument is the name of the nodelet+"_nodelet". Command only works when a *_nodelet.cpp-File is present in this folder.
    # FOLDER: Folder with cpp files for the executable, relative to cmake_current_list_dir
    # DEPENDS: List of extra (non-catkin, non-mrt) dependencies
    # LIBRARIES: Extra (non-catkin, non-mrt) libraries to link to
    set(NODELET_NAME ${ARGV0})
    if(NOT NODELET_NAME)
        message(FATAL_ERROR "No nodelet name specified for call to mrt_add_nodelet()!")
    endif()
    cmake_parse_arguments(MRT_ADD_NODELET "" "FOLDER" "DEPENDS;LIBRARIES" ${ARGN})
    set(NODELET_TARGET_NAME ${PROJECT_NAME}-${NODELET_NAME}-nodelet)

    # get the files
    file(GLOB NODELET_SOURCE_FILES_INC RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${MRT_ADD_NODELET_FOLDER}/*.h" "${MRT_ADD_NODELET_FOLDER}/*.hpp" "${MRT_ADD_EXECUTABLE_FOLDER}/*.hh")
    file(GLOB NODELET_SOURCE_FILES_SRC RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${MRT_ADD_NODELET_FOLDER}/*.cpp" "${MRT_ADD_EXECUTABLE_FOLDER}/*.cc")

    # Find nodelet
    file(GLOB NODELET_CPP RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${MRT_ADD_NODELET_FOLDER}/*_nodelet.cpp")
    if(NOT NODELET_SOURCE_FILES_SRC)
        return()
    endif()

    # Remove nodes (with their main) from src-files
    file(GLOB NODE_CPP RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${MRT_ADD_NODELET_FOLDER}/*_node.cpp")
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
    add_dependencies(${NODELET_TARGET_NAME} ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${MRT_ADD_NODELET_DEPENDS})
    target_link_libraries(${NODELET_TARGET_NAME}
        ${catkin_LIBRARIES}
        ${mrt_LIBRARIES}
        ${MRT_ADD_NODELET_LIBRARIES}
        )
    # append to list of all targets in this project
    set(${PACKAGE_NAME}_LIBRARIES ${${PACKAGE_NAME}_LIBRARIES} ${NODELET_TARGET_NAME} PARENT_SCOPE)
    set(${PACKAGE_NAME}_MRT_TARGETS ${${PACKAGE_NAME}_MRT_TARGETS} ${NODELET_TARGET_NAME} PARENT_SCOPE)
endfunction()


function(mrt_add_ros_tests)
    # adds all rostests (identified by a *.test file) to the project.
    # if a .cpp file exists with the same name it added and comiled as a gtest test.
    # takes the folder with tests as argument
    # LIBRARIES: Additional (non-catkin, non-mrt) libraries to link to
    # DEPENDENCIES: Additional (non-catkin, non-mrt) dependencies (e.g. with catkin_download_test_data)
    set(TEST_FOLDER ${ARGV0})
    cmake_parse_arguments(MRT_ADD_ROS_TESTS "" "" "LIBRARIES;DEPENDENCIES" ${ARGN})
    file(GLOB _ros_tests RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${TEST_FOLDER}/*.test")
    add_custom_target(${PROJECT_NAME}-rostest_test_files SOURCES ${_ros_tests})

    foreach(_ros_test ${_ros_tests})
        get_filename_component(_test_name ${_ros_test} NAME_WE)
        # make sure we add only one -test to the target
        STRING(REGEX REPLACE "-test" "" TEST_TARGET_NAME ${_test_name})
        set(TEST_TARGET_NAME ${TEST_TARGET_NAME}-test)
        # look for a matching .cpp
        if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/${TEST_FOLDER}/${_test_name}.cpp")
            message(STATUS "Adding gtest-rostest \"${TEST_TARGET_NAME}\" with test file ${_ros_test}")
            add_rostest_gtest(${TEST_TARGET_NAME} ${_ros_test} "${TEST_FOLDER}/${_test_name}.cpp")
            target_link_libraries(${TEST_TARGET_NAME} ${${PACKAGE_NAME}_LIBRARIES} ${catkin_LIBRARIES} ${mrt_LIBRARIES} ${MRT_ADD_ROS_TESTS_LIBRARIES} gtest_main)
            add_dependencies(${TEST_TARGET_NAME} ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${MRT_ADD_ROS_TESTS_DEPENDENCIES})
            set(TARGET_ADDED True)
        else()
            message(STATUS "Adding plain rostest \"${_ros_test}\"")
            add_rostest(${_ros_test}
                DEPENDENCIES ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${MRT_ADD_ROS_TESTS_DEPENDENCIES}
                )
        endif()
    endforeach()
    if(MRT_ENABLE_COVERAGE AND TARGET_ADDED AND NOT TARGET ${PROJECT_NAME}-coverage)
        setup_target_for_coverage(${PROJECT_NAME}-coverage coverage)
        # make sure the target is built after running tests
        add_dependencies(run_tests ${PROJECT_NAME}-coverage)
        add_dependencies(${PROJECT_NAME}-coverage _run_tests_${PROJECT_NAME})
    endif()
endfunction()


function(mrt_add_tests)
    # adds non-ros tests (with gtest) to the project
    # if a .cpp file exists with the same name it added and comiled as a gtest test.
    # takes the folder with tests as argument (package-relative).
    # This folder will be the working directory for the tests, so place your test data there.
    # LIBRARIES: Additional (non-catkin, non-mrt) libraries to link to
    # DEPENDENCIES: Additional (non-catkin, non-mrt) dependencies (e.g. with catkin_download_test_data)
    set(TEST_FOLDER ${ARGV0})
    cmake_parse_arguments(MRT_ADD_TESTS "" "" "LIBRARIES;DEPENDENCIES" ${ARGN})
    file(GLOB _tests RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${TEST_FOLDER}/*.cpp" "${TEST_FOLDER}/*.cc")

    foreach(_test ${_tests})
        get_filename_component(_test_name ${_test} NAME_WE)
        # make sure we add only one -test to the target
        STRING(REGEX REPLACE "-test" "" TEST_TARGET_NAME ${_test_name})
        set(TEST_TARGET_NAME ${TEST_TARGET_NAME}-test)
        # exclude cpp files with a test file (those are ros tests)
        if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/${TEST_FOLDER}/${_test_name}.test")
            message(STATUS "Adding gtest unittest \"${TEST_TARGET_NAME}\" with working dir ${CMAKE_CURRENT_LIST_DIR}/${TEST_FOLDER}")
            catkin_add_gtest(${TEST_TARGET_NAME} ${_test} WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${TEST_FOLDER})
            target_link_libraries(${TEST_TARGET_NAME} ${${PACKAGE_NAME}_LIBRARIES} ${catkin_LIBRARIES} ${mrt_LIBRARIES} ${MRT_ADD_TESTS_LIBRARIES} gtest_main)
            add_dependencies(${TEST_TARGET_NAME} ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${MRT_ADD_TESTS_DEPENDENCIES})
            set(TARGET_ADDED True)
        endif()
    endforeach()
    if(MRT_ENABLE_COVERAGE AND TARGET_ADDED AND NOT TARGET ${PROJECT_NAME}-coverage)
        setup_target_for_coverage(${PROJECT_NAME}-coverage coverage)
        # make sure the target is built after running tests
        add_dependencies(run_tests ${PROJECT_NAME}-coverage)
        add_dependencies(${PROJECT_NAME}-coverage _run_tests_${PROJECT_NAME})
    endif()
endfunction()


function(mrt_install)
    # Installs all targets
    # PROGRAMS: List of all folders and files that are programs (.py files will be treated separately)
    # FILEs: List of non-executable files and foldres
    cmake_parse_arguments(MRT_INSTALL "" "" "PROGRAMS;FILES" ${ARGN})

    # install targets
    if(${PACKAGE_NAME}_MRT_TARGETS)
        message(STATUS "Marking targets \"${${PACKAGE_NAME}_MRT_TARGETS}\" of package \"${PROJECT_NAME}\" for installation")
        install(TARGETS ${${PACKAGE_NAME}_MRT_TARGETS}
            ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
            LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
            RUNTIME DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
            )
    endif()

    # install header
    if(EXISTS ${CMAKE_CURRENT_LIST_DIR}/include/${PROJECT_NAME}/)
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
        # make it show up in IDEs
        STRING(REGEX REPLACE "/" "-" CUSTOM_TARGET_NAME ${PROJECT_NAME}-${program_path})
        add_custom_target(${CUSTOM_TARGET_NAME} SOURCES ${program_path})
    endfunction()

    # install programs
    foreach(ELEMENT ${MRT_INSTALL_PROGRAMS})
        if(IS_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${ELEMENT})
            file(GLOB FILES "${CMAKE_CURRENT_LIST_DIR}/${ELEMENT}/*")
            foreach(FILE ${FILES})
                mrt_install_program(${FILE})
            endforeach()
        elseif(EXISTS ${CMAKE_CURRENT_LIST_DIR}/${ELEMENT})
            mrt_install_program(${ELEMENT})
        endif()
    endforeach()

    # install files
    foreach(ELEMENT ${MRT_INSTALL_FILES})
        if(IS_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${ELEMENT})
            message(STATUS "Marking SHARED CONTENT FOLDER \"${ELEMENT}\" of package \"${PROJECT_NAME}\" for installation")
            install(DIRECTORY ${ELEMENT}
                DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
                )
            # make them show up in IDEs
            file(GLOB_RECURSE DIRECTORY_FILES RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${ELEMENT}/*")
            if(DIRECTORY_FILES)
                STRING(REGEX REPLACE "/" "-" CUSTOM_TARGET_NAME ${PROJECT_NAME}-${ELEMENT})
                add_custom_target(${CUSTOM_TARGET_NAME} SOURCES ${DIRECTORY_FILES})
            endif()
        elseif(EXISTS ${CMAKE_CURRENT_LIST_DIR}/${ELEMENT})
            message(STATUS "Marking FILE \"${ELEMENT}\" of package \"${PROJECT_NAME}\" for installation")
            install(FILES ${ELEMENT} DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION})
            STRING(REGEX REPLACE "/" "-" CUSTOM_TARGET_NAME ${PROJECT_NAME}-${ELEMENT})
            add_custom_target(${CUSTOM_TARGET_NAME} SOURCES ${ELEMENT})
        endif()
    endforeach()
endfunction()
