// Fixed-address accesses that only run on some iterations stay in the loop
// regardless of aliasing; "written every iteration" or "hoist it" is wrong.
void last_positive(const int *a, int *last, int n) {
  for (int i = 0; i < n; ++i)
    if (a[i] > 0)
      *last = i;
}
void add_bias(float *y, const float *bias, int n) {
  for (int i = 0; i < n; ++i)
    if (bias)
      y[i] += *bias;
}

// Written every iteration, blocked by a call that might read it: `pure`
// wouldn't help (the call could still read it); only `const` would.
int peek(void) __attribute__((pure));
void count(int *counter, int n) {
  for (int i = 0; i < n; ++i)
    *counter += peek();
}
