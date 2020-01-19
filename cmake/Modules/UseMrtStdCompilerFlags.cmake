# this file creates the target ${PROJECT_NAME}_${PROJECT_NAME}_compiler_flags and ${PROJECT_NAME}_${PROJECT_NAME}_private_compiler_flags that will be used by all targets created by mrt_cmake_modules

# export compile commands
set(CMAKE_EXPORT_COMPILE_COMMANDS YES)

add_library(${PROJECT_NAME}_compiler_flags INTERFACE)
add_library(${PROJECT_NAME}_private_compiler_flags INTERFACE)

# by default, at least c++14 is required to build externally, c++17 to build internally
if(CMAKE_VERSION VERSION_LESS "3.8")
    target_compile_options(${PROJECT_NAME}_compiler_flags INTERFACE -std=c++14)
    target_compile_options(${PROJECT_NAME}_private_compiler_flags INTERFACE -std=c++14)
else()
    target_compile_features(${PROJECT_NAME}_compiler_flags INTERFACE cxx_std_14)
    target_compile_features(${PROJECT_NAME}_private_compiler_flags INTERFACE cxx_std_17)
endif()

# Add _DEBUG and _GLIBCXX_ASSERTIONS for debug configuration. This enables e.g. assertions in OpenCV and the STL.
if (CMAKE_VERSION VERSION_GREATER "3.12")
    target_compile_definitions(${PROJECT_NAME}_private_compiler_flags INTERFACE $<$<CONFIG:Debug>:_DEBUG> $<$<CONFIG:Debug>:_GLIBCXX_ASSERTIONS>)
endif()

# Add support for std::filesystem. For GCC version <= 8 one needs to link against -lstdc++fs.
target_link_libraries(${PROJECT_NAME}_compiler_flags INTERFACE $<$<AND:$<CXX_COMPILER_ID:GNU>,$<VERSION_LESS:$<CXX_COMPILER_VERSION>,9.0>>:stdc++fs>)

# add OpenMP if present
# it would be great to have this in package.xmls instead, but catkin cannot handle setting the required cmake flags for dependencies
find_package(OpenMP)
if (OpenMP_FOUND)
    if(TARGET OpenMP::OpenMP_CXX)
        target_link_libraries(${PROJECT_NAME}_compiler_flags INTERFACE OpenMP::OpenMP_CXX)
    else()
        target_compile_options(${PROJECT_NAME}_compiler_flags INTERFACE
            $<$<COMPILE_LANGUAGE:CXX>:${OpenMP_CXX_FLAGS}>
            $<$<COMPILE_LANGUAGE:C>:${OpenMP_C_FLAGS}>
            )
        target_link_libraries(${PROJECT_NAME}_compiler_flags INTERFACE
            $<$<COMPILE_LANGUAGE:CXX>:${OpenMP_CXX_FLAGS}>
            $<$<COMPILE_LANGUAGE:C>:${OpenMP_C_FLAGS}>
            )
    endif()
endif()

# add gcov flags
set(gcc_like_cxx "$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:ARMClang,AppleClang,Clang,GNU>>")
set(gcc_cxx "$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:GNU>>")
set(gcc_like_c "$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:ARMClang,AppleClang,Clang,GNU>>")
if(MRT_ENABLE_COVERAGE)
    target_compile_options(${PROJECT_NAME}_private_compiler_flags INTERFACE
        $<${gcc_like_cxx}:-g;--coverage>
        $<${gcc_like_c}:-g;--coverage>
        )
    target_link_options(${PROJECT_NAME}_private_compiler_flags INTERFACE
        $<${gcc_like_cxx}:--coverage>
        $<${gcc_like_c}:--coverage>
        )
endif()

# add warning/error flags
# see here for documentation: https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html
# unused-parameter: ignored because ros_tools usually have unused parameters

if(MRT_COMPILE_ERROR)
    target_compile_options(${PROJECT_NAME}_private_compiler_flags INTERFACE
        $<${gcc_like_cxx}:-Wall -Wextra -Wno-unused-parameter>
        $<$<AND:$<${gcc_like_cxx},$<STREQUAL:MRT_COMPILE_ERROR,"all">>:-Werror=all>
        $<$<AND:$<${gcc_like_cxx},$<STREQUAL:MRT_COMPILE_ERROR,"off">>:-Wno-error=all>
        )
  if(MRT_COMPILE_ERROR STREQUAL "auto")
    set(MRT_USE_DEFAULT_WERROR_FLAGS TRUE)
  endif()
else()
  set(MRT_USE_DEFAULT_WERROR_FLAGS TRUE)
endif()


# ignored-attributes: ignored because of thousands of eigen 3.3 warnings
# no-int-in-bool-context: ignored because of thousands of eigen 3.3 warnings
# no-maybe-uninitialized: This causes some false positives with eigen.
# no-deprecated-copy: Too many warnings in Eigen
target_compile_options(${PROJECT_NAME}_private_compiler_flags INTERFACE
    $<${gcc_cxx}:-fdiagnostics-color=auto>
    $<$<AND:${gcc_cxx},$<VERSION_GREATER:$<CXX_COMPILER_VERSION>,6.3>>:-Wno-ignored-attributes>
    $<$<AND:${gcc_cxx},$<VERSION_GREATER:$<CXX_COMPILER_VERSION>,7>>:-Wno-int-in-bool-context;-Wno-maybe-uninitialized;-faligned-new>
    $<$<AND:${gcc_cxx},$<VERSION_GREATER:$<CXX_COMPILER_VERSION>,9>>:-Wno-deprecated-copy>
    )

if(MRT_USE_DEFAULT_WERROR_FLAGS)
    # the following -wall flags are not an error (please update this list):
    # - char-subscripts: Might cause false positives in openCV
    # - int-in-bool-context: Too many false positives in Eigen 3.3
    # - reorder: Too many errors reported
    # - sign-compare: Too many false positives in for-loops
    # - strict-overflow: False positives, optimization level dependent
    # - unknown-pragmas: Pragmas might be for a different compiler
    # - unused-*: Sometimes unused declarations are desired
    # - comment: Report errors in vtkMath.h for VTK6.
    target_compile_options(${PROJECT_NAME}_private_compiler_flags INTERFACE
        $<${gcc_cxx}:-Werror=address;-Werror=enum-compare;-Werror=format;-Werror=nonnull;-Werror=return-type;-Werror=sequence-point;-Werror=strict-aliasing;-Werror=switch;-Werror=trigraphs;-Werror=volatile-register-var>
        $<$<AND:${gcc_cxx},$<VERSION_GREATER:$<CXX_COMPILER_VERSION>,5>>:-Werror=array-bounds=1;-Werror=openmp-simd>
        $<$<AND:${gcc_cxx},$<VERSION_GREATER:$<CXX_COMPILER_VERSION>,6.3>>:-Werror=bool-compare;-Werror=init-self;-Werror=logical-not-parentheses;-Werror=memset-transposed-args;-Werror=nonnull-compare;-Werror=sizeof-pointer-memaccess;-Werror=tautological-compare;-Werror=uninitialized>
        $<$<AND:${gcc_cxx},$<VERSION_GREATER:$<CXX_COMPILER_VERSION>,7>>:-Werror=bool-operation;-Werror=memset-elt-size>
        $<$<AND:${gcc_cxx},$<VERSION_GREATER:$<CXX_COMPILER_VERSION>,8>>:-Werror=catch-value;-Werror=missing-attributes;-Werror=multistatement-macros;-Werror=restrict;-Werror=sizeof-pointer-div;-Werror=misleading-indentation>
        $<$<AND:${gcc_cxx},$<VERSION_GREATER:$<CXX_COMPILER_VERSION>,9>>:-Werror=pessimizing-move>
        )
endif()

# Include config file if set. This is done last so that the target ${PROJECT_NAME}_compiler_flags can be further modified
# The config file is supposed to contain system-specific configurations (basically like a cmake toolchain file)
if(MRT_CMAKE_CONFIG_FILE)
    message(STATUS "MRT CMake configuration file found: ${MRT_CMAKE_CONFIG_FILE}")
    include(${MRT_CMAKE_CONFIG_FILE})
elseif(DEFINED ENV{MRT_CMAKE_CONFIG_FILE})
    message(STATUS "MRT CMake configuration file found: $ENV{MRT_CMAKE_CONFIG_FILE}")
    include($ENV{MRT_CMAKE_CONFIG_FILE})
endif()
