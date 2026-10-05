// Not a running total: x = 0.5x + 1. Scan/reduction advice doesn't apply.
void shift_add(float *a, int n) {
  for (int i = 0; i < n; ++i)
    a[i + 1] = a[i] * 0.5f + 1.0f;
}

// Best value and where it was: a select-based recurrence.
int argmax(const float *a, int n) {
  int best = 0;
  float bestv = a[0];
  for (int i = 1; i < n; ++i)
    if (a[i] > bestv) {
      bestv = a[i];
      best = i;
    }
  return best;
}
