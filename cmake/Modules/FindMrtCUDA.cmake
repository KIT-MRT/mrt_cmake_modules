find_package(CUDA REQUIRED)

if(${CMAKE_VERSION} VERSION_LESS "3.9.0")
    if (${CUDA_VERSION_STRING} VERSION_LESS 10.0)
        set(CUDA_HOST_COMPILER "/usr/bin/g++-5")
    else()
        set(CUDA_HOST_COMPILER "/usr/bin/g++-7")
    endif()

    set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS} -Wno-deprecated-gpu-targets -std=c++11")
    set(CUDA_PROPAGATE_HOST_FLAGS OFF)
else()
    set(CMAKE_CUDA_COMPILER "${CUDA_TOOLKIT_ROOT_DIR}/bin/nvcc")

    if (${CUDA_VERSION_STRING} VERSION_LESS 10.0)
        set(CMAKE_CUDA_HOST_COMPILER "/usr/bin/g++-5")
    else()
        set(CMAKE_CUDA_HOST_COMPILER "/usr/bin/g++-7")
    endif()

    set(CMAKE_CUDA_FLAGS "-lineinfo")

    enable_language(CUDA)

    if(NOT DEFINED CMAKE_CUDA_STANDARD)
        set(CMAKE_CUDA_STANDARD 14)
        set(CMAKE_CUDA_STANDARD_REQUIRED ON)
    endif()

    set(CUDA_INCLUDE_DIRS "${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}")
endif()
