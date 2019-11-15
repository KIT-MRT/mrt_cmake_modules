#author: Johannes Beck
#email: Johannes.Beck@kit.edu
#license: GPLv3
#
#This package automatically find_package catkin and non-catkin packages.
#It has to be used together with GatherDeps.cmake.
#
#
#Variables used from the generate_cmake_depencency_file.py:
#_CATKIN_PACKAGES_: contains all catkin packages
#_CATKIN_EXPORT_PACKAGES_: contains only the catkin packages, which shall be exported
#
#_OTHER_PACKAGES_: contains all other packages
#_OTHER_EXPORT_PACKAGES_: contains only the mrt packages, which shall be exported
#_CUDA_CATKIN_PACKAGES_: contains all packages which should be linked to cuda
#_CUDA_OTHER_PACKAGES_: contains all packages which should be linked to cuda
#
#_<package name>_CMAKE_INCLUDE_DIRS_: contains the find package variable include cmake name
#_<package name>_CMAKE_LIBRARY_DIRS_: contains the find package variable libraries cmake name
#_<package name>_CMAKE_LIBRARIES_: contains the find package variable libraries cmake name
#_<package name>_CMAKE_COMPONENTS_: components used in find_package(...) for the package
#
#Variables set by this script:
#catkin_DEPENDS: Contains all catkin packages
#catkin_EXPORT_DEPENDS: Contains all catkin packages, which shall be exported. This shall be used in catkin_package
#
#mrt_INCLUDE_DIRS: Contains all include directories used for building the package
#mrt_LIBRARY_DIRS: Contains all library directories used for building the package
#mrt_LIBRARIES: Contains all libraries used for building the package
#mrt_CUDA_LIBRARIES: Contains all libraries which needs to be linked into cuda code.
#mrt_TEST_LIBRARIES: Contains all libraries which needs to be linked to test executables.
#mrt_EXPORT_INCLUDE_DIRS: Contains all include directories which dependend packages also need for building
#mrt_EXPORT_LIBRARIES: Contains all libraries which dependend packages also need for building

set(mrt_INCLUDE_DIRS "")
set(mrt_EXPORT_INCLUDE_DIRS "")
set(mrt_LIBRARIES "")
set(mrt_EXPORT_LIBRARIES "")
set(mrt_CUDA_LIBRARIES "")
set(mrt_TEST_LIBRARIES "")
set(mrt_LIBRARY_DIRS "")

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

# Detect Conan builds. In this case we don't have to do anything, just load the conanfile and include the catkin mock.
if(CONAN_PACKAGE_NAME OR EXISTS ${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
    if(NOT CONAN_PACKAGE_NAME)
        include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
    endif()
    include(CatkinMockForConan)
    return()
endif()

if (AutoDeps_FIND_COMPONENTS)
    #extract packages packages
    set(_CATKIN_SELECTED_PACKAGES_ "")
    set(_OTHER_SELECTED_PACKAGES_ "")
    set(_CATKIN_TEST_SELECTED_PACKAGES_ "")
    set(_OTHER_TEST_SELECTED_PACKAGES_ "")
    
    foreach(component ${AutoDeps_FIND_COMPONENTS})
        list(FIND _CATKIN_PACKAGES_ ${component} res)
        if(NOT ${res} EQUAL -1)
            list(APPEND _CATKIN_SELECTED_PACKAGES_ ${component})
            continue()
        endif()

        list(FIND _OTHER_PACKAGES_ ${component} res)
        if(NOT ${res} EQUAL -1)
            list(APPEND _OTHER_SELECTED_PACKAGES_ ${component})
            continue()
        endif()

        list(FIND _CATKIN_TEST_PACKAGES_ ${component} res)
        if(NOT ${res} EQUAL -1)
            list(APPEND _CATKIN_TEST_SELECTED_PACKAGES_ ${component})
            continue()
        endif()

        list(FIND _OTHER_TEST_PACKAGES_ ${component} res)
        if(NOT ${res} EQUAL -1)
            list(APPEND _OTHER_TEST_SELECTED_PACKAGES_ ${component})
            continue()
        endif()

        message(SEND_ERROR "Package ${component} specified but not found in package.xml. This package is ignored.")
    endforeach()
    
    if(CATKIN_ENABLE_TESTING)
        list(APPEND _CATKIN_SELECTED_PACKAGES_ ${_CATKIN_TEST_SELECTED_PACKAGES_})
        list(APPEND _OTHER_SELECTED_PACKAGES_ ${_OTHER_TEST_SELECTED_PACKAGES_})
    endif()
    
    #find catkin packages
    find_package(catkin REQUIRED COMPONENTS ${_CATKIN_SELECTED_PACKAGES_})

    #append catkin packages libraries to CUDA libraries
    foreach(cuda_package ${_CUDA_CATKIN_PACKAGES_})
        list(APPEND mrt_CUDA_LIBRARIES ${${cuda_package}_LIBRARIES})
    endforeach()
    
    #find other packages
    foreach(other_package ${_OTHER_SELECTED_PACKAGES_})
        #check, if cmake variable mapping is available
        if(NOT DEFINED _${other_package}_CMAKE_NAME_)
            message(FATAL_ERROR "Package ${other_package} is specified for autodepend but cmake variables are not defined. Did you resolve dependencies?")
        endif()
        
        #find non catkin modules
        if(DEFINED _${other_package}_CMAKE_COMPONENTS_)
            find_package(${_${other_package}_CMAKE_NAME_} REQUIRED COMPONENTS ${_${other_package}_CMAKE_COMPONENTS_})
        else()
            find_package(${_${other_package}_CMAKE_NAME_} REQUIRED)
        endif()
        
        #append found include directories
        if(DEFINED _${other_package}_CMAKE_INCLUDE_DIRS_)
            if(NOT DEFINED ${_${other_package}_CMAKE_INCLUDE_DIRS_})
                message(FATAL_ERROR "Package ${other_package}: Specified include dir variable ${_${other_package}_CMAKE_INCLUDE_DIRS_} not set.")
            endif()
        
            list(APPEND mrt_INCLUDE_DIRS ${${_${other_package}_CMAKE_INCLUDE_DIRS_}})
            
            list(FIND _OTHER_EXPORT_PACKAGES_ ${other_package} res)
            if(NOT ${res} EQUAL -1)
                list(APPEND mrt_EXPORT_INCLUDE_DIRS ${${_${other_package}_CMAKE_INCLUDE_DIRS_}})
            endif()
        endif()
        
        #append library directories
        if(DEFINED _${other_package}_CMAKE_LIBRARY_DIRS_)
            if(NOT DEFINED ${_${other_package}_CMAKE_LIBRARY_DIRS_})
                message(FATAL_ERROR "Package ${other_package}: Specified library dirs variable ${${_${other_package}_CMAKE_LIBRARY_DIRS_}} not set.")
            endif()
            
            list(APPEND mrt_LIBRARY_DIRS ${${_${other_package}_CMAKE_LIBRARY_DIRS_}})
        endif()
        
        #append libraries
        if(DEFINED _${other_package}_CMAKE_LIBRARIES_)
            if(NOT DEFINED ${_${other_package}_CMAKE_LIBRARIES_})
                message(FATAL_ERROR "Package ${other_package}: Specified libraries variable ${${_${other_package}_CMAKE_LIBRARIES_}} not set.")
            endif()

            # Append all libraries to link against a test executable (regular and test only).
            list(APPEND mrt_TEST_LIBRARIES ${${_${other_package}_CMAKE_LIBRARIES_}})

            list(FIND _OTHER_PACKAGES_ ${other_package} res)
            if(NOT ${res} EQUAL -1)
                list(APPEND mrt_LIBRARIES ${${_${other_package}_CMAKE_LIBRARIES_}})
            endif()

            list(FIND _OTHER_EXPORT_PACKAGES_ ${other_package} res)
            if(NOT ${res} EQUAL -1)
                list(APPEND mrt_EXPORT_LIBRARIES ${${_${other_package}_CMAKE_LIBRARIES_}})
            endif()

            list(FIND _CUDA_OTHER_PACKAGES_ ${other_package} res)
            if(NOT ${res} EQUAL -1)
                list(APPEND mrt_CUDA_LIBRARIES ${${_${other_package}_CMAKE_LIBRARIES_}})
            endif()
        endif()
    endforeach()
        
    # Cleanup include directories.
    _cleanup_includes(mrt_INCLUDE_DIRS)
    _cleanup_includes(mrt_EXPORT_INCLUDE_DIRS)
    _cleanup_includes(catkin_INCLUDE_DIRS)

    # Mark '/opt/mrtsoftware/...' include path as system headers, otherwise
    # the order can get messed up between 'local' and 'release'.
    set(_ALL_INCLUDE_DIRS ${mrt_INCLUDE_DIRS} ${catkin_INCLUDE_DIRS})
    if(_ALL_INCLUDE_DIRS)
        list(FIND _ALL_INCLUDE_DIRS "/opt/mrtsoftware/local/include" _FOUND_LOCAL)
        list(FIND _ALL_INCLUDE_DIRS "/opt/mrtsoftware/release/include" _FOUND_RELEASE)

        if (NOT ${_FOUND_LOCAL} EQUAL -1 OR NOT ${_FOUND_RELEASE} EQUAL -1)
            include_directories(SYSTEM "/opt/mrtsoftware/local/include" "/opt/mrtsoftware/release/include")
        endif()
    endif()

    #remove -lpthread from exports as this will not work with the catkin find package script.
    if(mrt_EXPORT_LIBRARIES)
        list(REMOVE_ITEM mrt_EXPORT_LIBRARIES "-lpthread")
    endif()

endif()

set(catkin_EXPORT_DEPENDS ${_CATKIN_EXPORT_PACKAGES_})
