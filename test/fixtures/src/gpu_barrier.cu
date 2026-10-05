#include "cuda_shim.h"

// Bug: threads with i >= n skip the barrier, which is undefined behaviour
// (the block can hang).
__global__ void stencil_bad(const float *in, float *out, int n) {
  __shared__ float s[258];
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n) {
    s[threadIdx.x + 1] = in[i];
    __syncthreads();
    out[i] = s[threadIdx.x] + s[threadIdx.x + 1] + s[threadIdx.x + 2];
  }
}

// Fixed: every thread reaches the barrier; only the work is guarded.
__global__ void stencil_ok(const float *in, float *out, int n) {
  __shared__ float s[258];
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n)
    s[threadIdx.x + 1] = in[i];
  __syncthreads();
  if (i < n)
    out[i] = s[threadIdx.x] + s[threadIdx.x + 1] + s[threadIdx.x + 2];
}
