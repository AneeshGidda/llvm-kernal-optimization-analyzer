#define N 256
// A[i][j] reads A[i+1][j-1]: dependence direction (<,>) in (j,i) order.
// Swapping the loops would make the inner walk sequential, but it reverses
// that dependence and changes the results, so it must not be advised.
void skew(float (*restrict A)[N]) {
  for (int j = 1; j < N - 1; ++j)
#pragma clang loop vectorize(disable) interleave(disable) unroll(disable)
    for (int i = 1; i < N - 1; ++i)
      A[i][j] = A[i + 1][j - 1] + 1.0f;
}
