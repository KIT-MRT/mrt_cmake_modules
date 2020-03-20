cmake_policy(PUSH)
if(POLICY CMP0074)
    cmake_policy(SET CMP0074 NEW)
endif()

# find package component
if(Mrtpcl_FIND_REQUIRED)
    find_package(PCL QUIET REQUIRED)
elseif(Mrtpcl_FIND_QUIETLY)
    find_package(PCL QUIET)
else()
    find_package(PCL QUIET)
endif()

add_library(mrt_pcl INTERFACE)

target_include_directories(mrt_pcl SYSTEM INTERFACE ${PCL_INCLUDE_DIRS})
set_target_properties(mrt_pcl
    PROPERTIES INTERFACE_LINK_DIRECTORIES ${PCL_LIBRARY_DIRS})
target_link_libraries(mrt_pcl INTERFACE ${PCL_LIBRARIES})

# Add PCL_NO_PRECOMPILE as this resolves Eigen issues.
target_compile_definitions(mrt_pcl INTERFACE PCL_NO_PRECOMPILE)

cmake_policy(POP)
