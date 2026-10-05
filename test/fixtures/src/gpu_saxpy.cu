#include "cuda_shim.h"

// Thread i handles element i: neighbouring threads touch neighbouring
// floats (coalesced), and `i < n` only splits the last warp.
__global__ void saxpy(float a, const float *x, float *y, int n) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n)
    y[i] = a * x[i] + y[i];
}

// Grid-stride loop: same pattern, any grid size.
__global__ void saxpy_grid_stride(float a, const float *x, float *y, int n) {
  for (int i = blockIdx.x * blockDim.x + threadIdx.x; i < n;
       i += blockDim.x * gridDim.x)
    y[i] = a * x[i] + y[i];
}
