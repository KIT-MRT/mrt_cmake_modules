#author: Johannes Beck, Fabian Poggenhans
#email: Johannes.Beck@kit.edu
#license: GPLv3
#
#This package automatically find_package catkin and non-catkin packages.
#It has to be used together with GatherDeps.cmake.
#
#
#Variables used from the generate_cmake_depencency_file.py:
#DEPENDEND_PACKAGES: all packages mentioned in package.xml
#_CATKIN_PACKAGES_: contains all catkin packages
#_MRT_PACKAGES_: contains all packages that are build_depends
#_MRT_EXPORT_PACKAGES_: contains all packages that are build_export_depends
#_MRT_CUDA_PACKAGES_: contains all packages which should be linked to cuda
#
#_<package name>_CMAKE_INCLUDE_DIRS_: contains the find package variable include cmake name
#_<package name>_CMAKE_LIBRARY_DIRS_: contains the find package variable libraries cmake name
#_<package name>_CMAKE_LIBRARIES_: contains the find package variable libraries cmake name
#_<package name>_CMAKE_COMPONENTS_: components used in find_package(...) for the package
#
# Sets the following targets:
# <prefix>auto_deps: A target that contains all targets that should be linked against internally
# <prefix>auto_deps_cuda: A target that contains all targets which needs to be linked into cuda code.
# <prefix>auto_deps_export: A target that contains all libraries which need to be linked publically
# <prefix>auto_deps_test: A target that contains all libraries which need to be additionally linked by tests. Contains no libraries if enable_testing is off.
#
# The prefix will be chosen based on the value of the variable AutoDeps_PREFIX if set.
#
# Also creates a target that has the name component::component for each component passed as an input unless the component itself already defines targets.

add_library(${AutoDeps_PREFIX}auto_deps INTERFACE IMPORTED)
add_library(${AutoDeps_PREFIX}auto_deps_test INTERFACE IMPORTED)
add_library(${AutoDeps_PREFIX}auto_deps_cuda INTERFACE IMPORTED)
add_library(${AutoDeps_PREFIX}auto_deps_export INTERFACE IMPORTED)

function(_cleanup_includes var_name_include_dir)
    if(${var_name_include_dir})
        # remove /usr/include and /usr/local/include
        # The compiler searches in those folders automatically and this can lead to 
        # problems if there are different versions of the same library installed
        # at different places.
        list(REMOVE_ITEM ${var_name_include_dir} "/usr/include" "/usr/local/include")
    endif()
    set (${var_name_include_dir} ${${var_name_include_dir}} PARENT_SCOPE)
endfunction()

function(_add_system_includes targetname)
    list(FIND ARGN "/opt/mrtsoftware/local/include" _FOUND_LOCAL)
    list(FIND ARGN "/opt/mrtsoftware/release/include" _FOUND_RELEASE)
    if(NOT ${_FOUND_LOCAL} EQUAL -1 OR NOT ${_FOUND_RELEASE} EQUAL -1)
        target_include_directories(${targetname} SYSTEM INTERFACE
            /opt/mrtsoftware/local/include;/opt/mrtsoftware/release/include
            )
    endif()
endfunction()

function(_remove_debug_libs libs_arg)
    set(filtered_libs)
    foreach(lib ${${libs_arg}})
        if(NOT lib MATCHES  "^\\$<\\$<CONFIG:DEBUG>:(.*)>")
            string(REGEX REPLACE "^\\$<\\$<NOT:\\$<CONFIG:DEBUG>>:(.*)>" "\\0" found ${lib})
            if(lib MATCHES "^\\$<\\$<NOT:\\$<CONFIG:DEBUG>>:(.*)>")
                list(APPEND filtered_libs ${CMAKE_MATCH_1})
            else()
                list(APPEND filtered_libs ${lib})
            endif()
        endif()
    endforeach()
    set(${libs_arg} ${filtered_libs} PARENT_SCOPE)
endfunction()

macro(_find_target output_target component)
    set(_targetname ${component}::${component})
    list(FIND _CATKIN_PACKAGES_ ${component} _is_catkin_package)
    message(STATUS "Finding target ${component}")
    if(TARGET ${_targetname})
        target_link_libraries(${output_target} INTERFACE ${_targetname})
        message("--> Already exists")
    elseif(NOT ${_is_catkin_package} EQUAL -1)
        # is catkin package
        find_package(${component} REQUIRED)
        if(NOT TARGET ${_targetname})
            # we have to create a new target. catkin does not create them.
            add_library(${_targetname} INTERFACE IMPORTED)
            if(${component}_INCLUDE_DIRS)
                target_include_directories(${_targetname} INTERFACE ${${component}_INCLUDE_DIRS})
            endif()
            if(${component}_LIBRARY_DIRS)
                target_link_directories(${_targetname} INTERFACE ${${component}_LIBRARY_DIRS})
            endif()
            if(${component}_LIBRARIES)
                target_link_libraries(${_targetname} INTERFACE ${${component}_LIBRARIES})
            endif()
            if(${component}_EXPORTED_TARGETS)
                add_dependencies(${_targetname} ${${component}_EXPORTED_TARGETS})
            endif()
            _add_system_includes(${_targetname} ${${component}_INCLUDE_DIRS})
        endif()
        target_link_libraries(${output_target} INTERFACE ${_targetname})
        message(STATUS "--> Is catkin package with include: ${${component}_INCLUDE_DIRS}, lib: ${${component}_LIBRARIES}")
        message(STATUS "found it at ${${component}_DIR}")
    else()
        # its an external package
        if(_${component}_NO_CMAKE_)
            # package is known to set no variables. do nothing.
        elseif(NOT DEFINED _${component}_CMAKE_NAME_)
            message(FATAL_ERROR "Package ${component} is specified for autodepend but no cmake definition was found. Did you resolve dependencies?")
        else()
            #find non-catkin modules
            if(DEFINED _${component}_CMAKE_COMPONENTS_)
                find_package(${_${component}_CMAKE_NAME_} REQUIRED COMPONENTS ${_${component}_CMAKE_COMPONENTS_})
            else()
                find_package(${_${component}_CMAKE_NAME_} REQUIRED)
            endif()

            # add them to auto_deps target
            if(DEFINED _${component}_CMAKE_TARGETS_)
                # the library already defines a target for us. Everything is good.
                target_link_libraries(${output_target} INTERFACE ${_${component}_CMAKE_TARGETS_})
                message(STATUS "--> Is externally defined target: ${_${component}_CMAKE_TARGETS_}")
            else()
                # the library defines no target. Create it from the variables it sets.
                add_library(${_targetname} INTERFACE IMPORTED)
                set(_includes ${${_${component}_CMAKE_INCLUDE_DIRS_}})
                message("HAVE includes: ${_includes}")
                _cleanup_includes(_includes)
                if(_includes)
                    target_include_directories(${_targetname} INTERFACE ${_includes})
                endif()
                if(${_${component}_CMAKE_LIBRARY_DIRS_})
                    target_link_directories(${_targetname} INTERFACE ${${_${component}_CMAKE_LIBRARY_DIRS_}})
                endif()
                if(${_${component}_CMAKE_LIBRARIES_})
                    target_link_libraries(${_targetname} INTERFACE ${${_${component}_CMAKE_LIBRARIES_}})
                endif()
                _add_system_includes(${_targetname} ${includes})
                unset(_includes)
                target_link_libraries(${output_target} INTERFACE ${_targetname})
                message(STATUS "--> Is externally defined variables: include: ${_includes}, libs: ${${_${component}_CMAKE_LIBRARIES_}}")
            endif() # package defines targets
        endif() # package definition is valid
    endif() # catkin vs normal package
    # cleanup
    unset(_targetname)
    unset(_is_catkin_package)
endmacro()

# Detect Conan builds. In this case we don't have to do anything, just load the conanfile and include the catkin mock.
if(CONAN_PACKAGE_NAME OR EXISTS ${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
    if(NOT CONAN_PACKAGE_NAME)
        include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
    endif()
    include(CatkinMockForConan)
    return()
endif()

if (AutoDeps_FIND_COMPONENTS)
    set(_CATKIN_SELECTED_PACKAGES_)
    foreach(_component ${AutoDeps_FIND_COMPONENTS})
        # figure out where this variable goes
        list(FIND _MRT_PACKAGES_ ${_component} _is_package)
        list(FIND _MRT_EXPORT_PACKAGES_ ${_component} _is_export_package)
        list(FIND _MRT_TEST_PACKAGES_ ${_component} _is_test_package)
        list(FIND _MRT_CUDA_PACKAGES_ ${_component} _is_cuda_package)
        if(NOT ${_is_export_package} EQUAL -1)
            _find_target(${AutoDeps_PREFIX}auto_deps_export ${_component})
            list(FIND _CATKIN_PACKAGES_ ${_component} _is_catkin_package)
            if(NOT ${_is_catkin_package} EQUAL -1)
                list(APPEND _CATKIN_SELECTED_PACKAGES_ ${_component})
            endif()
            unset(_is_catkin_package)
        elseif(NOT ${_is_package} EQUAL -1)
            _find_target(${AutoDeps_PREFIX}auto_deps ${_component})
        elseif(NOT ${_is_test_package} EQUAL -1)
            if(CATKIN_ENABLE_TESTING)
                _find_target(${AutoDeps_PREFIX}auto_deps_test ${_component})
            endif()
        else()
            message(SEND_ERROR "Package ${_component} specified but not found in package.xml. This package is ignored.")
        endif()
        if(NOT ${_is_cuda_package} EQUAL -1)
            _find_target(${AutoDeps_PREFIX}auto_deps_cuda ${_component})
        endif()
        unset(_is_package)
        unset(_is_export_package)
        unset(_is_test_package)
        unset(_is_cuda_package)
    endforeach()

    # set the variables as expected by catkin_package (for backwards compability)
    set(mrt_EXPORT_INCLUDE_DIRS "")
    set(mrt_EXPORT_LIBRARIES "")
    set(catkin_EXPORT_DEPENDS ${_CATKIN_SELECTED_PACKAGES_})
    get_target_property(_export_targets ${AutoDeps_PREFIX}auto_deps_export INTERFACE_LINK_LIBRARIES)
    if(NOT _export_targets)
        unset(_export_targets) # cmake sets it to "_export_targets-NOTFOUND". Sigh.
    endif()
    foreach(_target ${_export_targets})
        get_target_property(_target_type ${_target} TYPE)
        get_target_property(_target_include ${_target} INTERFACE_INCLUDE_DIRECTORIES)
        get_target_property(_target_sys_include ${_target} INTERFACE_SYSTEM_INCLUDE_DIRECTORIES)
        if(_target_include)
            list(APPEND mrt_EXPORT_INCLUDE_DIRS ${_target_include})
        endif()
        if(_target_sys_include)
           list(APPEND mrt_EXPORT_INCLUDE_DIRS ${target_sys_include})
        endif()
        if(NOT ${_target_type} STREQUAL "INTERFACE_LIBRARY")
            list(APPEND mrt_EXPORT_LIBRARIES ${_target})
        else()
            get_target_property(_target_link ${_target} INTERFACE_LINK_LIBRARIES)
            if(_target_link)
                list(APPEND mrt_EXPORT_LIBRARIES ${_target_link})
            endif()
        endif()
    endforeach()

    # cleanup and report
    unset(_target_include)
    unset(_target_link)
    unset(_CATKIN_SELECTED_PACKAGES_)
    list(REMOVE_DUPLICATES mrt_EXPORT_INCLUDE_DIRS)
    list(REMOVE_DUPLICATES mrt_EXPORT_LIBRARIES)
    _remove_debug_libs(mrt_EXPORT_LIBRARIES) # catkin cannot handle generator expressions (of type $<CONFIG::DEBUG:...>)
    message(STATUS "Includes: ${mrt_EXPORT_INCLUDE_DIRS}")
    message(STATUS "Libs: ${mrt_EXPORT_LIBRARIES}")
endif()
