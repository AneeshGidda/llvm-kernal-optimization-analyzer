// The blocker is the volatile store; LLVM's remark points at the loop.
void cond_volatile(const float *restrict x, volatile float *restrict y, int n) {
  for (int i = 0; i < n; ++i)
    if (x[i] > 0.0f)
      *y = x[i];
}
