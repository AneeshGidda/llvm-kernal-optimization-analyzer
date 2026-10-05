// BLAS-style stride: LLVM vectorizes only for incx == 1.
void scal(float *x, float a, int n, int incx) {
  for (int i = 0; i < n; ++i)
    x[i * incx] *= a;
}
