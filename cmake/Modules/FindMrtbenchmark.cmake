# we need this only because mrt_cmake_modules corrently does not support importing targets
# find package component
if(MrtOpenCV_FIND_REQUIRED)
	find_package(benchmark REQUIRED)
elseif(MrtOpenCV_FIND_QUIETLY)
	find_package(benchmark QUIET)
else()
	find_package(benchmark)
endif()

set(benchmark_LIBRARIES benchmark::benchmark)
