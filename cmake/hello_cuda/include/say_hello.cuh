#ifndef _SAY_HELLO_CU_H__
#define _SAY_HELLO_CU_H__

#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <stdlib.h>

__global__ void addKernel(int *c, const int *a, const int *b);

cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size);

#endif