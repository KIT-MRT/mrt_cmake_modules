if(MrtLAPACK_FIND_REQUIRED)
	find_package(LAPACK QUIET REQUIRED)
elseif(MrtLAPACK_FIND_QUIETLY)
	find_package(LAPACK QUIET)
else()
	find_package(LAPACK QUIET)
endif()

set(MrtLAPACK_FOUND LAPACK_FOUND)

# LAPACK_LIBRARIES are empty with cmake 3.16 but it is needed on ubuntu 18.04.
# Maybe this is a bug in the LAPACK cmake find script.
if (NOT LAPACK_LIBRARIES)
    set(LAPACK_LIBRARIES "lapack")
endif()
