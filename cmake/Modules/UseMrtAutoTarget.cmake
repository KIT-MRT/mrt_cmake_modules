function(add_executable_auto TARGET_NAME)
    set(FILE_LIST ${ARGN})
    if(NOT FILE_LIST)
        #Given file list empty. Generate a dummy file and use this as target.
        #Also warn the user
        set(_AUTO_GEN_FILE_NAME_ "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/${TARGET_NAME}_exec_dummy.cpp")

        file(GENERATE OUTPUT "${_AUTO_GEN_FILE_NAME_}" CONTENT "int main()\n{\n\t#warning \"Used auto generated file for target\"\n}")
        set_source_files_properties("${_AUTO_GEN_FILE_NAME_}" PROPERTIES GENERATED TRUE)
        list(APPEND FILE_LIST "${_AUTO_GEN_FILE_NAME_}")
        message(WARNING "No files specified for target ${TARGET_NAME}.")
    endif()

    add_executable(${TARGET_NAME} ${FILE_LIST})
endfunction()

function(add_library_auto TARGET_NAME)
    set(FILE_LIST ${ARGN})
    if(NOT FILE_LIST)
        #Given file list empty. Generate a dummy file and use this as target.
        #Also warn the user
        set(_AUTO_GEN_FILE_NAME_ "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/${TARGET_NAME}_lib_dummy.cpp")
        file(GENERATE OUTPUT "${_AUTO_GEN_FILE_NAME_}" CONTENT "#warning \"Used auto generated file for target\"\n")
        set_source_files_properties("${_AUTO_GEN_FILE_NAME_}" PROPERTIES GENERATED TRUE)
        list(APPEND FILE_LIST "${_AUTO_GEN_FILE_NAME_}")
        message(WARNING "No files specified for target ${TARGET_NAME}.")
    endif()

    add_library(${TARGET_NAME} ${FILE_LIST})
endfunction()

#search for subfolders in src
function(glob_folders DIRECTORY_LIST SEARCH_DIRECTORY)
    file(GLOB DIRECTORIES RELATIVE ${SEARCH_DIRECTORY} ${SEARCH_DIRECTORY}/[^.]*)
    set(_DIRECTORY_LIST_ "")
    foreach(SRC_DIR ${DIRECTORIES})
        if(IS_DIRECTORY ${SEARCH_DIRECTORY}/${SRC_DIR})
            list(APPEND _DIRECTORY_LIST_ ${SRC_DIR})
        endif()
    endforeach()
    set(${DIRECTORY_LIST} ${_DIRECTORY_LIST_} PARENT_SCOPE)
endfunction()

macro(glob_ros_files excecutable_name extension_name)
    file(GLOB ROS_${excecutable_name}_FILES RELATIVE "${CMAKE_CURRENT_LIST_DIR}/${extension_name}" "${extension_name}/*.${extension_name}")

    if (ROS_${excecutable_name}_FILES)
        #work around to execute a command wich name is given in a variable
        #write a file with the command, include it and delete the file again
        file(WRITE "${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/_GLOB_ROS_TEMP_FILE.cmake" "${excecutable_name}(
            DIRECTORY ${extension_name}
            FILES
            ${ROS_${excecutable_name}_FILES}
        )")
        include("${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/_GLOB_ROS_TEMP_FILE.cmake")
    file(REMOVE "${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/_GLOB_ROS_TEMP_FILE.cmake")

    set(ROS_GENERATE_MESSAGES True)
    endif()
endmacro()
