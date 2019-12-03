# requirement of cmake version
cmake_minimum_required(VERSION 2.8)
project(ffmpeg_test)

if( NOT CMAKE_MODULE_PATH )
  set( CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake-modules)
  message( STATUS "CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}" )
endif()

# find required opencv
find_package(FFmpeg REQUIRED)