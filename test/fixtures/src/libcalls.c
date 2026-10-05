void free(void *);
unsigned long strlen(const char *);
float sinf(float);

// Library functions with no vector version anywhere: -fveclib can't help.
void release_all(void **p, int n) {
  for (int i = 0; i < n; ++i)
    free(p[i]);
}
void lengths(unsigned long *restrict out, const char **restrict s, int n) {
  for (int i = 0; i < n; ++i)
    out[i] = strlen(s[i]);
}

// On Linux, sinf may set errno by default; that is the blocker there.
void apply_sin(float *restrict y, const float *restrict x, int n) {
  for (int i = 0; i < n; ++i)
    y[i] = sinf(x[i]);
}
