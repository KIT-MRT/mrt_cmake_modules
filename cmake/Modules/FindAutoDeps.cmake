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
#_${${AutoDeps}_PREFIX}_PACKAGES_: contains all packages that are build_depends
#_${${AutoDeps}_PREFIX}_EXPORT_PACKAGES_: contains all packages that are build_export_depends
#_${${AutoDeps}_PREFIX}_CUDA_PACKAGES_: contains all packages which should be linked to cuda
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
# The prefix will be chosen based on the value of the variable ${AutoDeps}_PREFIX if set. Otherwise it is set to "${PROJECT_NAME}"
#
# Also creates a target that has the name component::component for each component passed as an input unless the component itself already defines targets.
#
# For compability with catkin, this file also sets mrt_EXPORT_INCLUDE_DIRS and mrt_EXPORT_LIBRARIES to contain all headers
# and libraries that were found. These can be passed on to catkin_package. This behaviour can be disabled by setting AutoDeps_NO_CATKIN_EXPORT.
#
# A not for developers: This file is installed by several projects and might be executed recursively through find_packge.
# Therefore every variable that is not in a function must have a unique name.
if(NOT ${CMAKE_FIND_PACKAGE_NAME}_PREFIX)
    set(${CMAKE_FIND_PACKAGE_NAME}_PREFIX ${PROJECT_NAME})
endif()

add_library(${${CMAKE_FIND_PACKAGE_NAME}_PREFIX}::auto_deps INTERFACE IMPORTED)
add_library(${${CMAKE_FIND_PACKAGE_NAME}_PREFIX}::auto_deps_test INTERFACE IMPORTED)
add_library(${${CMAKE_FIND_PACKAGE_NAME}_PREFIX}::auto_deps_cuda INTERFACE IMPORTED)
add_library(${${CMAKE_FIND_PACKAGE_NAME}_PREFIX}::auto_deps_export INTERFACE IMPORTED)

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

function(_remove_generator_expressions libs_arg)
    set(filtered_libs)
    foreach(lib ${${libs_arg}})
        if(NOT lib MATCHES  "^\\$<\\$<CONFIG:DEBUG>:(.*)>")
            string(REGEX REPLACE "^\\$<\\$<NOT:\\$<CONFIG:DEBUG>>:(.*)>" "\\0" found ${lib})
            if(lib MATCHES "^\\$<\\$<NOT:\\$<CONFIG:DEBUG>>:(.*)>")
                list(APPEND filtered_libs ${CMAKE_MATCH_1})
            else()
                if(NOT lib MATCHES "^\\$\\<") # we simply drop all other generator expressions.
                    list(APPEND filtered_libs ${lib})
                endif()
            endif()
        endif()
    endforeach()
    set(${libs_arg} ${filtered_libs} PARENT_SCOPE)
endfunction()

function(_get_libs_and_incs_recursive out_libs out_incs lib)
    if(NOT TARGET ${lib})
        set(${out_libs} ${${out_libs}} ${lib} PARENT_SCOPE)
        return()
    else()
        get_target_property(_target_type ${lib} TYPE)
        if(NOT ${_target_type} STREQUAL "INTERFACE_LIBRARY")
            set(${out_libs} ${${out_libs}} ${lib} PARENT_SCOPE)
            return()
        endif()
    endif()
    get_target_property(_target_include ${lib} INTERFACE_INCLUDE_DIRECTORIES)
    get_target_property(_target_sys_include ${lib} INTERFACE_SYSTEM_INCLUDE_DIRECTORIES)
    set(inc)
    if(_target_include)
        list(APPEND inc ${_target_include})
    endif()
    if(_target_sys_include)
        list(APPEND inc ${_target_sys_include})
    endif()
    get_target_property(_target_link ${lib} INTERFACE_LINK_LIBRARIES)
    if(_target_link)
        foreach(lib ${_target_link})
            _get_libs_and_incs_recursive(${out_libs} ${out_incs} ${lib})
        endforeach()
    endif()
    set(${out_libs} ${${out_libs}} PARENT_SCOPE)
    set(${out_incs} ${${out_incs}} ${inc} PARENT_SCOPE)
endfunction()

macro(_find_target output_target component)
    set(${CMAKE_FIND_PACKAGE_NAME}_targetname ${component}::${component})
    list(FIND _${${CMAKE_FIND_PACKAGE_NAME}_PREFIX}_CATKIN_PACKAGES_ ${component} ${CMAKE_FIND_PACKAGE_NAME}_is_catkin_package)
    if(NOT ${${CMAKE_FIND_PACKAGE_NAME}_is_catkin_package} EQUAL -1)
        # is catkin package
        find_package(${component} REQUIRED)
        if(${component}_EXPORTS_TARGETS)
            # Simple case: Its another package that export targets
            if(${component}_LIBRARIES)
                set(${CMAKE_FIND_PACKAGE_NAME}_targetname ${${component}_LIBRARIES})
            else()
                unset(${CMAKE_FIND_PACKAGE_NAME}_targetname) # the imported project seems to be empty
            endif()
        elseif(NOT TARGET ${${CMAKE_FIND_PACKAGE_NAME}_targetname})
            # A normal catkin package that doesnt create targets. we have to create a new target.
            add_library(${${CMAKE_FIND_PACKAGE_NAME}_targetname} INTERFACE IMPORTED)
            if(${component}_INCLUDE_DIRS)
                target_include_directories(${${CMAKE_FIND_PACKAGE_NAME}_targetname} INTERFACE ${${component}_INCLUDE_DIRS})
            endif()
            if(${component}_LIBRARY_DIRS)
                target_link_directories(${${CMAKE_FIND_PACKAGE_NAME}_targetname} INTERFACE ${${component}_LIBRARY_DIRS})
            endif()
            if(${component}_LIBRARIES)
                target_link_libraries(${${CMAKE_FIND_PACKAGE_NAME}_targetname} INTERFACE ${${component}_LIBRARIES})
            endif()
            if(${component}_EXPORTED_TARGETS)
                add_dependencies(${${CMAKE_FIND_PACKAGE_NAME}_targetname} ${${component}_EXPORTED_TARGETS})
            endif()
            # TODO: All headers in imported targets are automatically "system" in cmake. In a future cmake version, this behaviour might be overridable.
        endif()
    else()
        # its an external package
        if(_${component}_NO_CMAKE_)
            # package is known to set no variables. do nothing.
            unset(${CMAKE_FIND_PACKAGE_NAME}_targetname)
        elseif(NOT DEFINED _${component}_CMAKE_NAME_)
            message(FATAL_ERROR "Package ${component} was not found. If it is a catkin package: Make sure it is present. If it is an external package: Make sure it is listed in mrt_cmake_modules/yaml/cmake.yaml!")
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
                set(${CMAKE_FIND_PACKAGE_NAME}_targetname ${_${component}_CMAKE_TARGETS_})
            elseif(NOT TARGET ${${CMAKE_FIND_PACKAGE_NAME}_targetname})
                # the library defines no target. Create it from the variables it sets.
                add_library(${${CMAKE_FIND_PACKAGE_NAME}_targetname} INTERFACE IMPORTED)
                set(${CMAKE_FIND_PACKAGE_NAME}_includes ${${_${component}_CMAKE_INCLUDE_DIRS_}})
                _cleanup_includes(${CMAKE_FIND_PACKAGE_NAME}_includes)
                if(${CMAKE_FIND_PACKAGE_NAME}_includes)
                    target_include_directories(${${CMAKE_FIND_PACKAGE_NAME}_targetname} INTERFACE ${${CMAKE_FIND_PACKAGE_NAME}_includes})
                endif()
                if(${_${component}_CMAKE_LIBRARY_DIRS_})
                    target_link_directories(${${CMAKE_FIND_PACKAGE_NAME}_targetname} INTERFACE ${${_${component}_CMAKE_LIBRARY_DIRS_}})
                endif()
                if(${_${component}_CMAKE_LIBRARIES_})
                    target_link_libraries(${${CMAKE_FIND_PACKAGE_NAME}_targetname} INTERFACE ${${_${component}_CMAKE_LIBRARIES_}})
                endif()
                unset(${CMAKE_FIND_PACKAGE_NAME}_includes)
            endif() # package defines targets
        endif() # package definition is valid
    endif() # catkin vs normal package
    # add the target(s) to the output target and cleanup
    if(${CMAKE_FIND_PACKAGE_NAME}_targetname)
        target_link_libraries(${output_target} INTERFACE ${${CMAKE_FIND_PACKAGE_NAME}_targetname})
        unset(${CMAKE_FIND_PACKAGE_NAME}_targetname)
    endif()
    unset(${CMAKE_FIND_PACKAGE_NAME}_is_catkin_package)
endmacro()

# Detect Conan builds. In this case we don't have to do anything, just load the conanfile and include the catkin mock.
if(CONAN_PACKAGE_NAME OR EXISTS ${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
    if(NOT CONAN_PACKAGE_NAME)
        include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
    endif()
    include(CatkinMockForConan)
    return()
endif()
if (${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
    set(${CMAKE_FIND_PACKAGE_NAME}_CATKIN_SELECTED_PACKAGES_)
    foreach(${CMAKE_FIND_PACKAGE_NAME}_component ${${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS})
        # figure out where this variable goes
        list(FIND _${${CMAKE_FIND_PACKAGE_NAME}_PREFIX}_PACKAGES_ ${${CMAKE_FIND_PACKAGE_NAME}_component} ${CMAKE_FIND_PACKAGE_NAME}_is_package)
        list(FIND _${${CMAKE_FIND_PACKAGE_NAME}_PREFIX}_EXPORT_PACKAGES_ ${${CMAKE_FIND_PACKAGE_NAME}_component} ${CMAKE_FIND_PACKAGE_NAME}_is_export_package)
        list(FIND _${${CMAKE_FIND_PACKAGE_NAME}_PREFIX}_TEST_PACKAGES_ ${${CMAKE_FIND_PACKAGE_NAME}_component} ${CMAKE_FIND_PACKAGE_NAME}_is_test_package)
        list(FIND _${${CMAKE_FIND_PACKAGE_NAME}_PREFIX}_CUDA_PACKAGES_ ${${CMAKE_FIND_PACKAGE_NAME}_component} ${CMAKE_FIND_PACKAGE_NAME}_is_cuda_package)
        if(NOT ${${CMAKE_FIND_PACKAGE_NAME}_is_export_package} EQUAL -1)
            _find_target(${${CMAKE_FIND_PACKAGE_NAME}_PREFIX}::auto_deps_export ${${CMAKE_FIND_PACKAGE_NAME}_component})
            list(FIND _${${CMAKE_FIND_PACKAGE_NAME}_PREFIX}_CATKIN_PACKAGES_ ${${CMAKE_FIND_PACKAGE_NAME}_component} ${CMAKE_FIND_PACKAGE_NAME}_is_catkin_package)
            if(NOT ${${CMAKE_FIND_PACKAGE_NAME}_is_catkin_package} EQUAL -1)
                list(APPEND ${CMAKE_FIND_PACKAGE_NAME}_CATKIN_SELECTED_PACKAGES_ ${${CMAKE_FIND_PACKAGE_NAME}_component})
            endif()
            unset(${CMAKE_FIND_PACKAGE_NAME}_is_catkin_package)
        elseif(NOT ${${CMAKE_FIND_PACKAGE_NAME}_is_package} EQUAL -1)
            _find_target(${${CMAKE_FIND_PACKAGE_NAME}_PREFIX}::auto_deps ${${CMAKE_FIND_PACKAGE_NAME}_component})
        elseif(NOT ${${CMAKE_FIND_PACKAGE_NAME}_is_test_package} EQUAL -1)
            if(CATKIN_ENABLE_TESTING)
                _find_target(${${CMAKE_FIND_PACKAGE_NAME}_PREFIX}::auto_deps_test ${${CMAKE_FIND_PACKAGE_NAME}_component})
            endif()
        else()
            message(SEND_ERROR "Package ${${CMAKE_FIND_PACKAGE_NAME}_component} specified but not found in package.xml. This package is ignored.")
        endif()
        if(NOT ${${CMAKE_FIND_PACKAGE_NAME}_is_cuda_package} EQUAL -1)
            _find_target(${${CMAKE_FIND_PACKAGE_NAME}_PREFIX}::auto_deps_cuda ${${CMAKE_FIND_PACKAGE_NAME}_component})
        endif()
        unset(${CMAKE_FIND_PACKAGE_NAME}_is_package)
        unset(${CMAKE_FIND_PACKAGE_NAME}_is_export_package)
        unset(${CMAKE_FIND_PACKAGE_NAME}_is_test_package)
        unset(${CMAKE_FIND_PACKAGE_NAME}_is_cuda_package)
    endforeach()

    # set the variables as expected by catkin_package (for backwards compability)
    if(${CMAKE_FIND_PACKAGE_NAME}_NO_CATKIN_EXPORT)
        unset(${CMAKE_FIND_PACKAGE_NAME}_CATKIN_SELECTED_PACKAGES_)
        return()
    endif()
    # this part is executed only once per package. We no longer have to use prefixes
    set(mrt_EXPORT_INCLUDE_DIRS "")
    set(mrt_EXPORT_LIBRARIES "")
    set(catkin_EXPORT_DEPENDS ${${CMAKE_FIND_PACKAGE_NAME}_CATKIN_SELECTED_PACKAGES_})
    get_target_property(_export_targets ${${CMAKE_FIND_PACKAGE_NAME}_PREFIX}::auto_deps_export INTERFACE_LINK_LIBRARIES)
    if(NOT _export_targets)
        unset(_export_targets) # cmake sets it to "_export_targets-NOTFOUND". Sigh.
    endif()
    foreach(_target ${_export_targets})
        _get_libs_and_incs_recursive(mrt_EXPORT_LIBRARIES mrt_EXPORT_INCLUDE_DIRS ${_target})
    endforeach()

    # cleanup and report
    unset(_target_include)
    unset(_target_link)
    unset(${CMAKE_FIND_PACKAGE_NAME}_CATKIN_SELECTED_PACKAGES_)
    list(REMOVE_DUPLICATES mrt_EXPORT_INCLUDE_DIRS)
    list(REMOVE_DUPLICATES mrt_EXPORT_LIBRARIES)
    _remove_generator_expressions(mrt_EXPORT_LIBRARIES) # catkin cannot handle generator expressions (of type $<CONFIG::DEBUG:...>)
endif()
