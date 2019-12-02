cmake_minimum_required(VERSION 2.8.12)
project(hello_server)

add_compile_options(-std=c++14)
add_compile_options(-fPIC)
include_directories(${CMAKE_SOURCE_DIR}/include ${CMAKE_SOURCE_DIR}/include/common ${CMAKE_SOURCE_DIR}/include/server)
link_directories(${CMAKE_SOURCE_DIR}/lib)

# compile server
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_SOURCE_DIR}/out/bin) 
file(GLOB_RECURSE SERVER_SOURCE_FILES ${CMAKE_SOURCE_DIR}/src/server/*.cpp ${CMAKE_SOURCE_DIR}/src/common/*.cpp) 
add_executable(${PROJECT_NAME} ${SERVER_SOURCE_FILES})
target_link_libraries(${PROJECT_NAME} hpsocket pthread)