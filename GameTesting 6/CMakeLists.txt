cmake_minimum_required(VERSION 3.10)
project(GameTesting)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

find_package(OpenGL REQUIRED)
find_package(GLUT REQUIRED)
find_package(SndFile REQUIRED)
find_package(OpenAL REQUIRED)
find_library(AVFOUNDATION_LIBRARY AVFoundation)

# Option to silence deprecation warnings for OpenGL
option(SILENCE_DEPRECATION "Silence deprecation warnings for OpenGL" ON)
if(SILENCE_DEPRECATION)
    add_definitions(-DGL_SILENCE_DEPRECATION)
endif()
mark_as_advanced(AVFOUNDATION_LIBRARY)
# Including directories
include_directories(${OPENGL_INCLUDE_DIRS} ${GLUT_INCLUDE_DIRS})
include_directories(/System/Library/Frameworks)
include_directories(${CMAKE_SOURCE_DIR}/path/to/stb)
include_directories(${SNDFILE_INCLUDE_DIRS})
include_directories(${OPENAL_INCLUDE_DIR})

# Define the executable with main.mm if using Objective-C features
add_executable(GameTesting main.mm stb_impl.cpp
)

# Finding and linking against the Cocoa library for Objective-C support
find_library(OPENGL_LIBRARY OpenGL)
find_library(GLUT_LIBRARY GLUT)
find_library(COCOA_LIBRARY Cocoa)
target_link_libraries(GameTesting ${OPENGL_LIBRARY} ${GLUT_LIBRARY} ${COCOA_LIBRARY} ${SNDFILE_LIBRARIES} ${OPENAL_LIBRARY} ${AVFOUNDATION_LIBRARY})

# Linking with OpenGL and GLUT libraries
target_link_libraries(GameTesting ${OPENGL_LIBRARIES} ${GLUT_LIBRARIES})
target_link_libraries(GameTesting "-framework OpenGL" "-framework GLUT")

# Ensure you add any other required framework or library






