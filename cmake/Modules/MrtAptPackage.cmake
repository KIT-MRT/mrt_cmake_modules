# Determine root of workspace.
execute_process(
    COMMAND catkin locate --src
    RESULT_VARIABLE _RES_ ERROR_VARIABLE _ERROR_ OUTPUT_VARIABLE _WORKSPACE_ROOT_DIR_)

if (NOT _RES_ EQUAL 0)
    message(FATAL_ERROR "Failed to determine workspace root dir: ${_ERROR_}")
endif()

# Run script to generate cpack cmake file.
execute_process(
    COMMAND python ${MCM_ROOT}/scripts/generate_cpack_cmake_file.py
        "${_WORKSPACE_ROOT_DIR_}"
        "${CMAKE_PROJECT_NAME}" 
        "${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/cpack_vars.cmake"
    RESULT_VARIABLE _RES_ ERROR_VARIABLE _ERROR_)

if (NOT _RES_ EQUAL 0)
    message(FATAL_ERROR "Generation of cpack cmake file failed: ${_ERROR_}")
endif()

# Include generated cpack cmake file.
include("${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/cpack_vars.cmake")