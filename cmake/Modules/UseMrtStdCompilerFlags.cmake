include(CheckCXXCompilerFlag)

#Require C++14
if (CMAKE_VERSION VERSION_LESS "3.1")
  CHECK_CXX_COMPILER_FLAG("-std=c++14" Cpp14CompilerFlag)
  if (${Cpp14CompilerFlag})
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
    set(CMAKE_CXX_STANDARD 14)
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS "17")
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    #no additional flag is required
  else()
    message(FATAL_ERROR "Compiler does not have c++14 support. Use at least g++4.9 or Visual Studio 2013 and newer.")
  endif()
elseif (CMAKE_VERSION VERSION_LESS "3.8")
  # c++17 is not supported in cmake 3.7 and earlier
  set(CMAKE_CXX_STANDARD 14)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
else()
  # we dont require it since compilers might still support only 14
  set(CMAKE_CXX_STANDARD 17)
endif ()

# use gold linker
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fuse-ld=gold")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fuse-ld=gold")

# Add support for std::filesystem. For GCC version <= 8 one needs to link agains -lstdc++fs.
link_libraries($<$<AND:$<CXX_COMPILER_ID:GNU>,$<VERSION_LESS:$<CXX_COMPILER_VERSION>,9.0>>:stdc++fs>)
link_libraries($<$<AND:$<CXX_COMPILER_ID:GNU>,$<CONFIG:Debug>>:-Wl,--gdb-index>)

# export compile commands
if(${CMAKE_VERSION} VERSION_GREATER "3.5.0")
    set(CMAKE_EXPORT_COMPILE_COMMANDS YES)
endif()

# Select arch flag
if(MRT_ARCH)
  if(NOT MRT_ARCH STREQUAL "None" AND NOT MRT_ARCH STREQUAL "none")
    set(_arch "-march=${MRT_ARCH}")
  endif()
else()
  # sandybridge is the lowest common cpu arch for us
  set(_arch "-march=sandybridge")
endif()
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${_arch}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${_arch}")

#add OpenMP
find_package(OpenMP REQUIRED)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")

# add gcov flags
if(MRT_ENABLE_COVERAGE)
    include(MRTCoverage)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g --coverage")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g --coverage")
endif()

# add warning/error flags
# see here for documentation: https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html
# unused-parameter: ignored because ros_tools usually have unused parameters

if(MRT_COMPILE_ERROR)
  if(MRT_COMPILE_ERROR STREQUAL "all")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror=all")
    set(MRT_USE_DEFAULT_WERROR_FLAGS FALSE)
  elseif(MRT_COMPILE_ERROR STREQUAL "off")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-error=all")
    set(MRT_USE_DEFAULT_WERROR_FLAGS FALSE)
  elseif(MRT_COMPILE_ERROR STREQUAL "auto")
    set(MRT_USE_DEFAULT_WERROR_FLAGS TRUE)
  else()
    message(FATAL_ERROR "Don't know how to handle value '${MRT_COMPILE_ERROR}' in variable MRT_COMPILE_ERROR, must be one of all auto off. Exiting.")
  endif()
else()
  set(MRT_USE_DEFAULT_WERROR_FLAGS TRUE)
endif()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wno-unused-parameter")
if(MRT_USE_DEFAULT_WERROR_FLAGS)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror=address -Werror=comment -Werror=enum-compare -Werror=format -Werror=nonnull -Werror=return-type -Werror=sequence-point -Werror=strict-aliasing -Werror=switch -Werror=trigraphs -Werror=uninitialized -Werror=volatile-register-var")
endif()

if(CMAKE_COMPILER_IS_GNUCC)
  if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 5 AND MRT_USE_DEFAULT_WERROR_FLAGS)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror=array-bounds=1 -Werror=openmp-simd ")
  endif()
  if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 6.3)
    if(MRT_USE_DEFAULT_WERROR_FLAGS)
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror=bool-compare -Werror=init-self -Werror=logical-not-parentheses -Werror=memset-transposed-args -Werror=nonnull-compare -Werror=sizeof-pointer-memaccess -Werror=tautological-compare")
    endif()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-ignored-attributes") # ignored-attributes: ignored because of thousands of eigen 3.3 warnings
  endif()
  if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 7)
    if(MRT_USE_DEFAULT_WERROR_FLAGS)
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror=bool-operation -Werror=memset-elt-size")
    endif()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -faligned-new")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-int-in-bool-context") # no-int-in-bool-context: ignored because of thousands of eigen 3.3 warnings
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-maybe-uninitialized") # This causes some false positives with eigen.
  endif()
  if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 8)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-copy") # Too many warnings in Eigen
  endif()
endif()



# the following -wall flags are not an error (please update this list):
# - catch-value: Not part of 7.2
# - char-subscripts: Might cause false positives in openCV
# - int-in-bool-context: Too many false positives in Eigen 3.3
# - misleading-indentation: Too many false positives in Eigen 3.3
# - multistatement-macros: Not part of 7.2
# - reorder: Too many errors reported
# - restict: Not part of 7.2
# - sign-compare: Too many false positives in for-loops
# - sizeof-pointer-div: Not part of 7.2
# - strict-overflow: False positives, optimization level dependent
# - unknown-pragmas: Pragmas might be for a different compiler
# - unused-*: Sometimes unused declarations are desired

#add compiler flags
CHECK_CXX_COMPILER_FLAG("-fdiagnostics-color=auto" FLAG_AVAILABLE)
if (${FLAG_AVAILABLE})
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fdiagnostics-color=auto")
endif()
