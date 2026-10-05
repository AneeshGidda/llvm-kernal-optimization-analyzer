// Each iteration reads the previous iteration's result: a true dependence.
void prefix_sum(float *a, const float *b, int n) {
  for (int i = 1; i < n; ++i)
    a[i] = a[i - 1] + b[i];
}
