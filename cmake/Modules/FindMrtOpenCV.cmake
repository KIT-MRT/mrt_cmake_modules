# find package component
if(MrtOpenCV_FIND_REQUIRED)
	find_package(OpenCV REQUIRED)
elseif(MrtOpenCV_FIND_QUIETLY)
	find_package(OpenCV QUIET)
else()
	find_package(OpenCV)
endif()
