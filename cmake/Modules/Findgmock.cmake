# copied from Findgtest.cmake and adopted.
if(CATKIN_ENABLE_TESTING)
    set(gmock_INCLUDE_DIRS "")
    set(gmock_LIBRARIES gmock)
else()
    message(FATAL_ERROR "CMake script only implemented for gtest as test_depend")
endif()
