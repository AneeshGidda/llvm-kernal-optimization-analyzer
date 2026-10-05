// Float sum: blocked unless reassociation is allowed.
float sum_f32(const float *a, int n) {
  float s = 0.0f;
  for (int i = 0; i < n; ++i)
    s += a[i];
  return s;
}

// Integer sum: integer addition reassociates freely, so this vectorizes.
int sum_i32(const int *a, int n) {
  int s = 0;
  for (int i = 0; i < n; ++i)
    s += a[i];
  return s;
}
