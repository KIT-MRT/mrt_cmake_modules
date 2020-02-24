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

cmake_policy(POP)
