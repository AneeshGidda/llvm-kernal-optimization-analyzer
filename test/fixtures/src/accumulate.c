// *out might point into a[], so *out is re-loaded and re-stored every
// iteration instead of being kept in a register.
void accumulate(float *out, const float *a, int n) {
  for (int i = 0; i < n; ++i)
    *out += a[i];
}

// *scale might alias y[], so the load of *scale can't be hoisted.
void scale_by_ptr(float *y, const float *scale, int n) {
  for (int i = 0; i < n; ++i)
    y[i] = y[i] * *scale;
}
