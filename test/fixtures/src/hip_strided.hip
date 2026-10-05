// HIP kernel compiled for AMD (gfx90a, 64-thread wavefronts). Uses the
// AMDGPU builtins directly so no ROCm install is needed.
#define __global__ __attribute__((global))

__global__ void scale_column(float *m, float s, int n) {
  int row = __builtin_amdgcn_workgroup_id_x() * 256 +
            __builtin_amdgcn_workitem_id_x();
  if (row < n)
    m[row * n] *= s;
}

__global__ void scale_row(float *m, float s, int n) {
  int i = __builtin_amdgcn_workgroup_id_x() * 256 +
          __builtin_amdgcn_workitem_id_x();
  if (i < n)
    m[i] *= s;
}
