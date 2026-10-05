// Column walk with a constant trip count: LLVM only interleaves the inner
// loop (x2) and leaves no remainder, so the only copy is unrolled. Rows are
// 256 floats; the stride must be reported as 256, not 512.
void colwalk_const(float out[restrict 256][256],
                   const float in[restrict 256][256]) {
  for (int j = 0; j < 256; ++j)
    for (int i = 0; i < 256; ++i)
      out[i][j] = 2.0f * in[i][j];
}
