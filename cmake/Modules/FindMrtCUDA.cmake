if(${CMAKE_VERSION} VERSION_LESS "3.9.0")
    find_package(CUDA REQUIRED)
else()
    if (NOT DEFINED CMAKE_CUDA_COMPILER)
        set(CMAKE_CUDA_COMPILER /usr/local/cuda/bin/nvcc)
        set(CMAKE_CUDA_FLAGS "-lineinfo")
    endif()

    enable_language(CUDA)

    if(NOT DEFINED CMAKE_CUDA_STANDARD)
        set(CMAKE_CUDA_STANDARD 14)
        set(CMAKE_CUDA_STANDARD_REQUIRED ON)
    endif()

    set(CUDA_INCLUDE_DIRS "${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}")
    set(CUDA_LIBRARIES "cuda")
endif()
