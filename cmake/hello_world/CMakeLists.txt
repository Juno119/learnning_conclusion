cmake_minimum_required(VERSION 2.8.12)
project(hello_world)

add_compile_options(-std=c++11)

# compile libhello.so
set(LIBRARY_OUTPUT_PATH ${CMAKE_SOURCE_DIR}/out/lib)
set(HELLO_LIBRARY_NAME "hello")
file(GLOB_RECURSE HELLO_SOURCE_FILES ${CMAKE_SOURCE_DIR}/src/hello_world.cpp)
add_library(${HELLO_LIBRARY_NAME} SHARED  ${HELLO_SOURCE_FILES})
message(${CMAKE_SOURCE_DIR})
target_include_directories(${HELLO_LIBRARY_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/include)

# compile main
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_SOURCE_DIR}/out/bin) 
file(GLOB_RECURSE MAIN_SOURCE_FILES ${CMAKE_SOURCE_DIR}/src/main.cpp)
add_executable(${PROJECT_NAME} ${MAIN_SOURCE_FILES})
target_link_libraries(${PROJECT_NAME} ${HELLO_LIBRARY_NAME})
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/include)
