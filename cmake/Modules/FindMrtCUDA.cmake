find_package(CUDA REQUIRED)

if (${CUDA_VERSION_STRING} VERSION_LESS 10.0)
    set(_CUDA_HOST_COMPILER "g++-6")
elseif(${CUDA_VERSION_STRING} VERSION_LESS 10.2)
    set(_CUDA_HOST_COMPILER "g++-7")
else()
    set(_CUDA_HOST_COMPILER "g++-8")
endif()

if(${CMAKE_VERSION} VERSION_LESS "3.9.0")
    set(CUDA_HOST_COMPILER "${_CUDA_HOST_COMPILER}")

    set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS} -Wno-deprecated-gpu-targets -std=c++14")
    if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
        set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS} -lineinfo -g --compiler-options -fPIC")
    else()
        set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS} -DNDEBUG -O3 --compiler-options -fPIC")
    endif()

    set(CUDA_PROPAGATE_HOST_FLAGS OFF)
else()
    set(CMAKE_CUDA_COMPILER "${CUDA_TOOLKIT_ROOT_DIR}/bin/nvcc")
    set(CMAKE_CUDA_HOST_COMPILER "${_CUDA_HOST_COMPILER}")
    set(CMAKE_CUDA_FLAGS "-lineinfo --expt-relaxed-constexpr")

    enable_language(CUDA)

    if(NOT DEFINED CMAKE_CUDA_STANDARD)
        set(CMAKE_CUDA_STANDARD 14)
        set(CMAKE_CUDA_STANDARD_REQUIRED ON)
    endif()

    set(CUDA_INCLUDE_DIRS "${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}")
endif()
