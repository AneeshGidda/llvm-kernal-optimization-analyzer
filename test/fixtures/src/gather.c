// Address depends on loaded data: x[idx[i]].
void gather(const float *x, const int *idx, float *y, int n) {
  for (int i = 0; i < n; ++i)
    y[i] = x[idx[i]];
}
