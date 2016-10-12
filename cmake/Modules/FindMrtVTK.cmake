set(PACKAGE_LOCAL_PATH "/mrtsoftware/pkg/local/vtk-6.2.0/lib/cmake/vtk-6.2")
set(PACKAGE_PATH "/mrtsoftware/pkg/vtk-6.2.0/lib/cmake/vtk-6.2")

# old /mrtsoftware style
if (EXISTS ${PACKAGE_LOCAL_PATH})
	set(VTK_DIR ${PACKAGE_LOCAL_PATH})
elseif(EXISTS ${PACKAGE_PATH})
	set(VTK_DIR ${PACKAGE_PATH})
endif()

# find package component
if(MrtVTK_FIND_REQUIRED)
	find_package(VTK REQUIRED)
elseif(MrtVTK_FIND_QUIETLY)
	find_package(VTK QUIET)
else()
	find_package(VTK)
endif()

