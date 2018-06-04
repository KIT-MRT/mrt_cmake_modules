include(CheckCXXCompilerFlag)

#Clean any compiler flags to avoid issues with werr (to be removed in future)
set(CMAKE_CXX_FLAGS "")

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
else ()
  set(CMAKE_CXX_STANDARD 14)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif ()

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
# ignored-attributes: ignored because of thousands of eigen 3.3 warnings
# no-int-in-bool-context: ignored because of thousands of eigen 3.3 warnings
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wno-unused-parameter")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror=address -Werror=enum-compare -Werror=format -Werror=maybe-uninitialized -Werror=nonnull -Werror=openmp-simd -Werror=parentheses -Werror=return-type -Werror=sequence-point -Werror=strict-aliasing -Werror=switch -Werror=trigraphs -Werror=uninitialized -Werror=volatile-register-var")

if(CMAKE_COMPILER_IS_GNUCC AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 5)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror=array-bounds=1")
endif()
if(CMAKE_COMPILER_IS_GNUCC AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 6.3)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror=bool-compare -Werror=init-self -Werror=logical-not-parentheses -Werror=memset-transposed-args -Werror=nonnull-compare -Werror=sizeof-pointer-memaccess -Werror=tautological-compare")
endif()
if(CMAKE_COMPILER_IS_GNUCC AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 7)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror=bool-operation -Werror=memset-elt-size")
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

