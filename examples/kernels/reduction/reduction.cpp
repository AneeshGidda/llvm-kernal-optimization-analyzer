// Simple reduction kernel for analyzer demo
float reduce_sum(const float* x, int n) {
  float acc = 0;
  for (int i = 0; i < n; ++i)
    acc += x[i];
  return acc;
}
