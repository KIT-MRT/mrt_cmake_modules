# This file lets a conan build look like a catkin build for the rest of the tools. This is done by defining all
# the variables that the rest of the build system would expect
set(catkin_FOUND TRUE)
message(STATUS "testing: ${CATKIN_ENABLE_TESTING}")

set(catkin_LIBRARIES ${CONAN_LIBS})
set(MRT_ARCH ${CONAN_SETTINGS_ARCH})
set(mrt_LIBRARIES ${${PROJECT_NAME}_LIBRARIES})

set(CATKIN_DEVEL_PREFIX ${CMAKE_CURRENT_BINARY_DIR})
set(CATKIN_GLOBAL_PYTHON_DESTINATION ${CMAKE_INSTALL_LIBDIR}/python${PYTHON_VERSION}/dist-packages)
set(CATKIN_PACKAGE_LIB_DESTINATION ${CMAKE_INSTALL_LIBDIR})
set(CATKIN_PACKAGE_BIN_DESTINATION ${CMAKE_INSTALL_BINDIR})
set(CATKIN_PACKAGE_INCLUDE_DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
set(CATKIN_PACKAGE_SHARE_DESTINATION ${CMAKE_INSTALL_DATAROOTDIR})

function(catkin_package)
endfunction()
function(catkin_install_python programs)
    cmake_parse_arguments(ARG "OPTIONAL" "DESTINATION" "" ${ARGN})
    if(ARG_OPTIONAL)
        set(optional_flag "OPTIONAL")
    endif()
    foreach(file ${ARG_UNPARSED_ARGUMENTS})
        install(PROGRAMS "${file}" DESTINATION "${ARG_DESTINATION}" ${optional_flag})
    endforeach()
endfunction()