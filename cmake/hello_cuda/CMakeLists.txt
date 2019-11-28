cmake_minimum_required(VERSION 2.8.12)
project(hello_cuda)

add_compile_options(-std=c++11)

find_package(CUDA QUIET REQUIRED)
# nvcc flags
set(CUDA_NVCC_FLAGS -gencode arch=compute_12,code=sm_12;-G;-g)

include_directories(${CMAKE_SOURCE_DIR}/include)

# compile libhello.so
set(LIBRARY_OUTPUT_PATH ${CMAKE_SOURCE_DIR}/out/lib)
set(HELLO_LIBRARY_NAME "sayHello")
file(GLOB_RECURSE HELLO_SOURCE_FILES ${CMAKE_SOURCE_DIR}/src/say_hello.cu)
cuda_add_library(${HELLO_LIBRARY_NAME} SHARED  ${HELLO_SOURCE_FILES})

# compile main
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_SOURCE_DIR}/out/bin) 
file(GLOB_RECURSE MAIN_SOURCE_FILES ${CMAKE_SOURCE_DIR}/src/main.cu)
cuda_add_executable(${PROJECT_NAME} ${MAIN_SOURCE_FILES})
target_link_libraries(${PROJECT_NAME} ${HELLO_LIBRARY_NAME})