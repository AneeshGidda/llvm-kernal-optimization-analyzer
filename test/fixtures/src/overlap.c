// One array conflicting with itself: `restrict` can't help.
void self_dep(float *a, int n) {
  for (int i = 0; i < n; ++i)
    a[2 * i] = a[i] + 1.0f;
}

// Histogram: the conflict is h[idx[i]] vs h[idx[j]], not h vs idx.
void histogram(int *h, const int *idx, int n) {
  for (int i = 0; i < n; ++i)
    h[idx[i]]++;
}

// Vectorized behind an A-vs-A overlap check; A is already restrict.
void stencil_rows(float *restrict A, int n, int m, int k) {
  for (int i = 0; i < n; ++i)
    for (int j = 0; j < m; ++j)
      A[i * m + j] += A[(i + k) * m + j];
}
