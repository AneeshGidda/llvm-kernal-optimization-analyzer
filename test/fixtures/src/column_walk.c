// Inner loop walks down a column of a row-major matrix (stride n).
// Swapping the loops makes every access sequential.
void scale_columns(float *restrict out, const float *restrict in, int n) {
  for (int j = 0; j < n; ++j)
    for (int i = 0; i < n; ++i)
      out[i * n + j] = 2.0f * in[i * n + j];
}
