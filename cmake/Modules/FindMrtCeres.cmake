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

