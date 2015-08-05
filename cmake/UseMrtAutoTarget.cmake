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
	message("SEARCH_DIRECTORY: ${SEARCH_DIRECTORY}")
	execute_process(COMMAND find . -mindepth 1 -type d WORKING_DIRECTORY "${SEARCH_DIRECTORY}" OUTPUT_VARIABLE DIRECTORIES)
	
	set(_DIRECTORY_LIST_ "")
	if (NOT DIRECTORIES STREQUAL "")
		string(REPLACE "\n" ";" DIRECTORIES ${DIRECTORIES})
	
		foreach(SRC_DIR ${DIRECTORIES})
			#remove trailing "./"
			string(SUBSTRING "${SRC_DIR}" 2 -1 EXEC_NAME)
			list(APPEND _DIRECTORY_LIST_ ${EXEC_NAME})
		endforeach()
		
		set(${DIRECTORY_LIST} ${_DIRECTORY_LIST_} PARENT_SCOPE)
	endif()
endfunction()

