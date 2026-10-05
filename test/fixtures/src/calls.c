#include <math.h>

float transform(float);

// libm call: vectorizable only with a vector math library (-fveclib).
void apply_sin(const float *restrict x, float *restrict y, int n) {
  for (int i = 0; i < n; ++i)
    y[i] = sinf(x[i]);
}

// Opaque external function: the compiler can't see inside it.
void apply_transform(const float *restrict x, float *restrict y, int n) {
  for (int i = 0; i < n; ++i)
    y[i] = transform(x[i]);
}
