// Just enough of the CUDA headers to compile kernels to device IR with
// clang alone (-nocudainc): no CUDA SDK is needed to regenerate fixtures.
#pragma once
#define __global__ __attribute__((global))
#define __device__ __attribute__((device))
#define __shared__ __attribute__((shared))
#include <__clang_cuda_builtin_vars.h>
