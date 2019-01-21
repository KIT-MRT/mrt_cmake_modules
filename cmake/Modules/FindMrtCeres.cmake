#Use the following block, if a package config file is already created by cmake.
#Adjust the following paths if needed.
set(PACKAGE_LOCAL_PATH "/mrtsoftware/pkg/local/ceres-1.10.0/share/Ceres")
set(PACKAGE_PATH "/mrtsoftware/pkg/ceres-1.10.0/share/Ceres")

if (EXISTS ${PACKAGE_LOCAL_PATH})
	set(Ceres_DIR ${PACKAGE_LOCAL_PATH})
elseif(EXISTS ${PACKAGE_PATH})
	set(Ceres_DIR ${PACKAGE_PATH})
endif()

# find package component
if(MrtCeres_FIND_REQUIRED)
	find_package(Ceres REQUIRED)
elseif(MrtCeres_FIND_QUIETLY)
	find_package(Ceres QUIET)
else()
	find_package(Ceres)
endif()

if(NOT CERES_INCLUDE_DIRS AND CERES_LIBRARIES)
    # Newer ceres versions no longer set CERS_INCLUDE_DIRS
    get_target_property(CERES_INCLUDE_DIRS ceres INTERFACE_INCLUDE_DIRECTORIES)
endif()

