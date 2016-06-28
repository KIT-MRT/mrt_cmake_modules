#Use the following block, if a package config file is already created by cmake.
#Adjust the following paths if needed.
set(PACKAGE_LOCAL_PATH "/mrtsoftware/pkg/local/caffe-0.9/share/Caffe")
set(PACKAGE_PATH "/mrtsoftware/pkg/caffe-0.9/share/Caffe")

if (EXISTS ${PACKAGE_LOCAL_PATH})
	set(Caffe_DIR ${PACKAGE_LOCAL_PATH})
elseif(EXISTS ${PACKAGE_PATH})
	set(Caffe_DIR ${PACKAGE_PATH})
else()
	message(SEND_ERROR "Error: Caffe package not found. Install the appropriate mrt package.")
endif()

# find package component
if(MrtCaffe_FIND_REQUIRED)
	find_package(Caffe REQUIRED)
elseif(MrtCaffe_FIND_QUIETLY)
	find_package(Caffe QUIET)
else()
	find_package(Caffe)
endif()

