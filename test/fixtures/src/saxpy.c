// x and y may overlap, so the vectorized loop runs behind a runtime check.
void saxpy(float a, const float *x, float *y, int n) {
  for (int i = 0; i < n; ++i)
    y[i] = a * x[i] + y[i];
}

// restrict tells the compiler they don't overlap: no runtime check needed.
void saxpy_restrict(float a, const float *restrict x, float *restrict y, int n) {
  for (int i = 0; i < n; ++i)
    y[i] = a * x[i] + y[i];
}
