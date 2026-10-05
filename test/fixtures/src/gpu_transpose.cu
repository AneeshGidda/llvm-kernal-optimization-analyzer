#include "cuda_shim.h"

#define TILE 32

// Naive transpose: reads are coalesced, writes jump a row per thread.
__global__ void transpose_naive(const float *in, float *out, int n) {
  int x = blockIdx.x * TILE + threadIdx.x;
  int y = blockIdx.y * TILE + threadIdx.y;
  out[x * n + y] = in[y * n + x];
}

// Tiled through shared memory: both global accesses coalesced, but
// tile[threadIdx.x][...] puts every thread of a warp in the same bank.
__global__ void transpose_tiled(const float *in, float *out, int n) {
  __shared__ float tile[TILE][TILE];
  int x = blockIdx.x * TILE + threadIdx.x;
  int y = blockIdx.y * TILE + threadIdx.y;
  tile[threadIdx.y][threadIdx.x] = in[y * n + x];
  __syncthreads();
  x = blockIdx.y * TILE + threadIdx.x;
  y = blockIdx.x * TILE + threadIdx.y;
  out[y * n + x] = tile[threadIdx.x][threadIdx.y];
}

// The fix: one column of padding moves each row to a different bank.
__global__ void transpose_padded(const float *in, float *out, int n) {
  __shared__ float tile[TILE][TILE + 1];
  int x = blockIdx.x * TILE + threadIdx.x;
  int y = blockIdx.y * TILE + threadIdx.y;
  tile[threadIdx.y][threadIdx.x] = in[y * n + x];
  __syncthreads();
  x = blockIdx.y * TILE + threadIdx.x;
  y = blockIdx.x * TILE + threadIdx.y;
  out[y * n + x] = tile[threadIdx.x][threadIdx.y];
}
