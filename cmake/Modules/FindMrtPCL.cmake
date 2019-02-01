#Use the following block, if a package config file is already created by cmake.
#Adjust the following paths if needed.
set(PACKAGE_LOCAL_PATH "/mrtsoftware/pkg/local/pcl-1.8/share/pcl-1.8")
set(PACKAGE_PATH "/mrtsoftware/pkg/pcl-1.8/share/pcl-1.8")

cmake_policy(PUSH)
if(POLICY CMP0074)
	cmake_policy(SET CMP0074 NEW)
endif()

#old mrtsoftware-style
if (EXISTS ${PACKAGE_LOCAL_PATH})
	set(PCL_DIR ${PACKAGE_LOCAL_PATH})
elseif(EXISTS ${PACKAGE_PATH})
	set(PCL_DIR ${PACKAGE_PATH})
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
