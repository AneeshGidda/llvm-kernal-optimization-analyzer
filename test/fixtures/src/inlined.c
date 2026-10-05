float transform(float);

// One source loop inlined twice: the copies must be reported separately.
static inline void apply(float *restrict y, const float *restrict x, int n,
                         int opaque) {
  for (int i = 0; i < n; ++i)
    y[i] = opaque ? transform(x[i]) : 2.0f * x[i];
}

void two_calls(float *restrict a, float *restrict b, const float *restrict x,
               int n) {
  apply(a, x, n, 0);  // vectorizes
  apply(b, x, n, 1);  // blocked by the opaque call
}
