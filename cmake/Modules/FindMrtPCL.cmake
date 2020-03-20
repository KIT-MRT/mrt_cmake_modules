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

add_library(pcl_target INTERFACE)
target_include_directories(pcl_target INTERFACE ${PCL_INCLUDE_DIRS})
target_link_directories(pcl_target INTERFACE ${PCL_LIBRARY_DIRS})
target_link_libraries(pcl_target INTERFACE ${PCL_LIBRARIES})

# Add PCL_NO_PRECOMPILE as this resolves Eigen issues.
target_compile_definitions(pcl_target INTERFACE PCL_NO_PRECOMPILE)

cmake_policy(POP)
