# Copyright (c) 2012 - 2015, Lars Bilke
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors
#    may be used to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
#
# 2012-01-31, Lars Bilke
# - Enable Code Coverage
#
# 2013-09-17, Joakim Söderberg
# - Added support for Clang.
# - Some additional usage instructions.
#
# USAGE:

# 0. (Mac only) If you use Xcode 5.1 make sure to patch geninfo as described here:
#      http://stackoverflow.com/a/22404544/80480
#
# 1. Copy this file into your cmake modules path.
#
# 2. Add the following line to your CMakeLists.txt:
#      INCLUDE(CodeCoverage)
#
# 3. Set compiler flags to turn off optimization and enable coverage:
#    SET(CMAKE_CXX_FLAGS "-g -O0 -fprofile-arcs -ftest-coverage")
#	 SET(CMAKE_C_FLAGS "-g -O0 -fprofile-arcs -ftest-coverage")
#
# 3. Use the function SETUP_TARGET_FOR_COVERAGE to create a custom make target
#    which runs your test executable and produces a lcov code coverage report:
#    Example:
#	 SETUP_TARGET_FOR_COVERAGE(
#				my_coverage_target  # Name for custom target.
#				test_driver         # Name of the test driver executable that runs the tests.
#									# NOTE! This should always have a ZERO as exit code
#									# otherwise the coverage generation will not complete.
#				coverage            # Name of output directory.
#				)
#
# 4. Build a Debug build:
#	 cmake -DCMAKE_BUILD_TYPE=Debug ..
#	 make
#	 make my_coverage_target
#
#

# Check prereqs
FIND_PROGRAM( GCOV_PATH gcov )
FIND_PROGRAM( LCOV_PATH lcov )
FIND_PROGRAM( GENHTML_PATH genhtml )
if("${CMAKE_CXX_COMPILER_VERSION}" VERSION_GREATER 8)
    # lcov is unreliable above gcc 8
    FIND_PROGRAM( GCOVR_PATH gcovr PATHS ${CMAKE_SOURCE_DIR}/tests)
endif()

IF(NOT GCOV_PATH)
	MESSAGE(FATAL_ERROR "gcov not found! Aborting...")
ENDIF() # NOT GCOV_PATH

IF("${CMAKE_CXX_COMPILER_ID}" MATCHES "(Apple)?[Cc]lang")
	IF("${CMAKE_CXX_COMPILER_VERSION}" VERSION_LESS 3)
		MESSAGE(FATAL_ERROR "Clang version must be 3.0.0 or greater! Aborting...")
	ENDIF()
ELSEIF(NOT CMAKE_COMPILER_IS_GNUCXX)
	MESSAGE(FATAL_ERROR "Compiler is not GNU gcc! Aborting...")
ENDIF() # CHECK VALID COMPILER

IF ( NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
  MESSAGE( WARNING "Code coverage results with an optimized (non-Debug) build may be misleading" )
ENDIF() # NOT CMAKE_BUILD_TYPE STREQUAL "Debug"

function(_setup_lcov_target _targetname _outputname _init_targetname)
    	SET(coverage_baseline "${CMAKE_CURRENT_BINARY_DIR}/${_outputname}.baseline")
	SET(coverage_info "${CMAKE_CURRENT_BINARY_DIR}/${_outputname}.info")
	SET(coverage_combined "${coverage_info}.combined")
	SET(coverage_cleaned "${coverage_info}.cleaned")

	message(STATUS "Adding initial coverage target  ${_init_targetname}")
	ADD_CUSTOM_TARGET(${_init_targetname}
		COMMAND ${LCOV_PATH} --directory ${CMAKE_CURRENT_BINARY_DIR} --capture --initial --output-file ${coverage_baseline} -q
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		COMMENT "Initializing code coverage counters"
	)

	if(NOT GENHTML_PATH)
		MESSAGE(FATAL_ERROR "genhtml not found! Aborting...")
	ENDIF() # NOT GENHTML_PATH

	# Setup target
	message(STATUS "Adding postprocess coverage target ${_targetname}")

	ADD_CUSTOM_TARGET(${_targetname}
		# Capturing lcov counters and generating report
		COMMAND ${LCOV_PATH} --directory ${CMAKE_CURRENT_BINARY_DIR} --capture --output-file ${coverage_info} -q
		COMMAND ${LCOV_PATH} -a ${coverage_info} -a ${coverage_baseline} --output-file ${coverage_combined} -q || true
		COMMAND ${LCOV_PATH} --extract ${coverage_combined} '${CMAKE_CURRENT_LIST_DIR}/*' --output-file ${coverage_cleaned} -q || true
		COMMAND ${GENHTML_PATH} -o ${_outputname} ${coverage_cleaned} || true
		COMMAND ${CMAKE_COMMAND} -E remove ${coverage_info} ${coverage_combined}

		# Cleanup lcov
		COMMAND ${LCOV_PATH} --directory ${CMAKE_CURRENT_BINARY_DIR} --zerocounters -q

		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		COMMENT "Processing code coverage counters and generating report."
	)
endfunction()


function(_setup_gcovr_target _targetname _outputname _init_targetname)
	message(STATUS "Adding coverage target ${_targetname} using gcovr")
	if(ENV{MRT_MIN_COVERAGE})
        set(MIN_COVERAGE "--fail-under-line $ENV{MRT_MIN_COVERAGE} ")
	endif()
	ADD_CUSTOM_TARGET(${_targetname}
	    COMMAND mkdir -p ${_outputname}
	    COMMAND if [ ! -z "$$MRT_MIN_COVERAGE" ]; then export MIN_COVERAGE=\"--fail-under-line $$MRT_MIN_COVERAGE\"$<SEMICOLON> fi$<SEMICOLON> ${GCOVR_PATH} -j 4  -s  -r ${CMAKE_CURRENT_LIST_DIR} $$MIN_COVERAGE --object-directory ${CMAKE_CURRENT_BINARY_DIR} --html-details --html-title "${PROJECT_NAME} coverage" -o ${_outputname}/index.html || (>&2 echo "Coverage $$MRT_MIN_COVERAGE% not reached!" && false)
	    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		COMMENT "Processing code coverage counters and generating report."
	)
endfunction()

# Param _targetname      The name of new the custom make target to run _after_ the executables
# Param _outputname      lcov output is generated as _outputname.info
#                        HTML report is generated in _outputname/index.html
# Param _init_targetname The name of the target to run _before_ the executables
FUNCTION(SETUP_TARGET_FOR_COVERAGE _targetname _outputname _init_targetname)

	IF(NOT LCOV_PATH AND NOT GCOVR_PATH)
		MESSAGE(FATAL_ERROR "lcov not found! Aborting...")
	ENDIF() # NOT LCOV_PATH

	if(LCOV_PATH)
        _setup_lcov_target(${_targetname} ${_outputname} ${_init_targetname})
    else()
        _setup_gcovr_target(${_targetname} ${_outputname} ${_init_targetname})
    endif()

	# Show info where to find the report
	ADD_CUSTOM_COMMAND(TARGET ${_targetname} POST_BUILD
		COMMAND ;
		COMMENT "Open ${CMAKE_CURRENT_BINARY_DIR}/${_outputname}/index.html in your browser to view the coverage report."
	)

ENDFUNCTION() # SETUP_TARGET_FOR_COVERAGE

