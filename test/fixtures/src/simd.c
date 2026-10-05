#include <arm_neon.h>

// Already SIMD: written with NEON intrinsics. Not a missed vectorization.
void add_neon(float *restrict y, const float *restrict x, int n) {
  for (int i = 0; i + 4 <= n; i += 4)
    vst1q_f32(y + i, vaddq_f32(vld1q_f32(y + i), vld1q_f32(x + i)));
}

// Vectorization disabled: LLVM only interleaves it, then the SLP vectorizer
// packs the interleaved copies. Must not be credited to the loop vectorizer.
void scale_disabled(float *restrict y, const float *restrict x, int n) {
#pragma clang loop vectorize(disable)
  for (int i = 0; i < n; ++i)
    y[i] = 2.0f * x[i];
}

// The inner loop (64 iterations) is vectorized and then fully unrolled, so
// the outer loop becomes innermost and contains vector code.
void rows(float *restrict out, const float *restrict in, int n) {
  for (int r = 0; r < n; ++r)
    for (int c = 0; c < 64; ++c)
      out[r * 64 + c] = in[r * 64 + c] * 3.0f;
}
