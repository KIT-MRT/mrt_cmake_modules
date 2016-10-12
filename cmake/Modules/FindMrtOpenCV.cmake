#Use the following block, if a package config file is already created by cmake.
#Adjust the following paths if needed.
set(PACKAGE_LOCAL_PATH "/mrtsoftware/pkg/local/opencv-2.4.11/share/OpenCV")
set(PACKAGE_PATH "/mrtsoftware/pkg/opencv-2.4.11/share/OpenCV")

#old mrtsoftware-style
if (EXISTS ${PACKAGE_LOCAL_PATH})
	set(OpenCV_DIR ${PACKAGE_LOCAL_PATH})
elseif(EXISTS ${PACKAGE_PATH})
	set(OpenCV_DIR ${PACKAGE_PATH})
endif()

# find package component
if(MrtOpenCV_FIND_REQUIRED)
	find_package(OpenCV REQUIRED)
elseif(MrtOpenCV_FIND_QUIETLY)
	find_package(OpenCV QUIET)
else()
	find_package(OpenCV)
endif()
