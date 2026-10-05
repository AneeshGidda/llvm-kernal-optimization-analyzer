#include "cuda_shim.h"

struct Particle {
  float x, y, z;
};

// Array of structs: thread i reads p[i].x, 12 bytes after thread i-1's.
__global__ void shift_x(Particle *p, float dx, int n) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n)
    p[i].x += dx;
}

// Each thread owns a row and walks along it: neighbouring threads are a
// whole row (n floats) apart.
__global__ void row_sums(const float *m, float *out, int n) {
  int row = blockIdx.x * blockDim.x + threadIdx.x;
  if (row >= n)
    return;
  float s = 0.0f;
  for (int j = 0; j < n; ++j)
    s += m[row * n + j];
  out[row] = s;
}

// Every other element: half of each memory segment is wasted.
__global__ void take_even(const float *in, float *out, int n) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n)
    out[i] = in[2 * i];
}
