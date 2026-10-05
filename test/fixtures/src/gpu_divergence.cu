#include "cuda_shim.h"

// Classic interleaved tree reduction: `tid % (2*s) == 0` keeps every other
// thread of each warp active, so every warp runs every step.
__global__ void reduce_interleaved(const float *in, float *out) {
  __shared__ float buf[256];
  unsigned tid = threadIdx.x;
  buf[tid] = in[blockIdx.x * 256 + tid];
  __syncthreads();
  for (unsigned s = 1; s < 256; s *= 2) {
    if (tid % (2 * s) == 0)
      buf[tid] += buf[tid + s];
    __syncthreads();
  }
  if (tid == 0)
    out[blockIdx.x] = buf[0];
}

// Fixed: active threads are contiguous, so whole warps retire together.
__global__ void reduce_sequential(const float *in, float *out) {
  __shared__ float buf[256];
  unsigned tid = threadIdx.x;
  buf[tid] = in[blockIdx.x * 256 + tid];
  __syncthreads();
  for (unsigned s = 128; s > 0; s /= 2) {
    if (tid < s)
      buf[tid] += buf[tid + s];
    __syncthreads();
  }
  if (tid == 0)
    out[blockIdx.x] = buf[0];
}

// Scalar CSR sparse matrix-vector product, one thread per row: rows have
// different lengths, and each thread reads its own part of val/col.
__global__ void spmv_csr_scalar(const int *rowStart, const int *col,
                                const float *val, const float *x, float *y,
                                int rows) {
  int row = blockIdx.x * blockDim.x + threadIdx.x;
  if (row < rows) {
    float sum = 0.0f;
    for (int k = rowStart[row]; k < rowStart[row + 1]; ++k)
      sum += val[k] * x[col[k]];
    y[row] = sum;
  }
}

// Odd and even threads want different paths, but both sides are short:
// -O2 turns this into a select, so no branch (and no divergence) remains.
__global__ void odd_even_select(float *a, int n) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i >= n)
    return;
  if (threadIdx.x % 2 == 0)
    a[i] = a[i] * 2.0f;
  else
    a[i] = a[i] + 1.0f;
}

// Stores to different arrays keep the branch: odd and even threads of
// every warp diverge.
__global__ void odd_even_branch(float *a, float *b, int n) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i >= n)
    return;
  if (threadIdx.x % 2 == 0)
    a[i] *= 2.0f;
  else
    b[i] += 1.0f;
}

// Every thread reads the same flag: the branch is uniform even though the
// value comes from memory.
__global__ void uniform_flag(const int *flag, float *a, int n) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n && *flag)
    a[i] = 0.0f;
}
