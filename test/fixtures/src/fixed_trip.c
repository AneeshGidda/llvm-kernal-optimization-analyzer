// The rerun on optimized IR blames float order; clang's compile-time
// decision was the cost model. --remarks must report the latter.
float sum1003(const float *a) {
  float s = 0.0f;
  for (int i = 0; i < 1003; ++i)
    s += a[i];
  return s;
}
