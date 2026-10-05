#include "cuda_shim.h"

// Naive matmul, threadIdx.x on the column: B[k*n + col] and C are
// coalesced, A[row*n + k] is the same address for the whole warp.
__global__ void matmul(const float *A, const float *B, float *C, int n) {
  int row = blockIdx.y * blockDim.y + threadIdx.y;
  int col = blockIdx.x * blockDim.x + threadIdx.x;
  if (row < n && col < n) {
    float sum = 0.0f;
    for (int k = 0; k < n; ++k)
      sum += A[row * n + k] * B[k * n + col];
    C[row * n + col] = sum;
  }
}

// Same math with threadIdx.x on the row: A and C are now a row apart per
// thread.
__global__ void matmul_swapped(const float *A, const float *B, float *C,
                               int n) {
  int row = blockIdx.x * blockDim.x + threadIdx.x;
  int col = blockIdx.y * blockDim.y + threadIdx.y;
  if (row < n && col < n) {
    float sum = 0.0f;
    for (int k = 0; k < n; ++k)
      sum += A[row * n + k] * B[k * n + col];
    C[row * n + col] = sum;
  }
}
