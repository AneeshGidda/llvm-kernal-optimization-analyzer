// Early exit: the iteration count isn't known before the loop starts.
int find_first(const int *a, int n, int key) {
  for (int i = 0; i < n; ++i)
    if (a[i] == key)
      return i;
  return -1;
}
