// Naive i-j-k matrix multiply. Two real problems:
//  1. The k loop is a float sum, which LLVM won't reorder without fast-math.
//  2. B[k*n + j] jumps a whole row per k iteration (column walk).
void matmul(const float *A, const float *B, float *C, int n) {
  for (int i = 0; i < n; ++i)
    for (int j = 0; j < n; ++j) {
      float sum = 0.0f;
      for (int k = 0; k < n; ++k)
        sum += A[i * n + k] * B[k * n + j];
      C[i * n + j] = sum;
    }
}
