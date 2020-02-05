# only required to silence cmake warnings
set(OpenGL_GL_PREFERENCE GLVND)
if(MrtOpenGL_FIND_REQUIRED)
        find_package(OpenGL QUIET REQUIRED)
elseif(MrtOpenGL_FIND_QUIETLY)
        find_package(OpenGL QUIET)
else()
        find_package(OpenGL QUIET)
endif()
set(MrtOpenGL_FOUND ${OpenGL_FOUND})