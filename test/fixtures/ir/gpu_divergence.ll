; ModuleID = 'gpu_divergence.cu'
source_filename = "gpu_divergence.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

@_ZZ18reduce_interleavedPKfPfE3buf = internal unnamed_addr addrspace(3) global [256 x float] undef, align 4
@_ZZ17reduce_sequentialPKfPfE3buf = internal unnamed_addr addrspace(3) global [256 x float] undef, align 4

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z18reduce_interleavedPKfPf(ptr nocapture noundef readonly %in, ptr nocapture noundef writeonly %out) local_unnamed_addr #0 !dbg !15 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !18
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !22
  %mul = shl i32 %1, 8, !dbg !25
  %add = add i32 %mul, %0, !dbg !26
  %idxprom = zext i32 %add to i64, !dbg !27
  %arrayidx = getelementptr inbounds float, ptr %in, i64 %idxprom, !dbg !27
  %2 = load float, ptr %arrayidx, align 4, !dbg !27, !tbaa !28
  %idxprom2 = zext i32 %0 to i64, !dbg !32
  %arrayidx3 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ18reduce_interleavedPKfPfE3buf to ptr), i64 0, i64 %idxprom2, !dbg !32
  store float %2, ptr %arrayidx3, align 4, !dbg !33, !tbaa !28
  tail call void @llvm.nvvm.barrier0(), !dbg !34
  %rem = and i32 %0, 1, !dbg !35
  %cmp5 = icmp eq i32 %rem, 0, !dbg !36
  br i1 %cmp5, label %if.then, label %if.end, !dbg !37

if.then:                                          ; preds = %entry
  %add6 = add nuw i32 %0, 1, !dbg !38
  %idxprom7 = zext i32 %add6 to i64, !dbg !39
  %arrayidx8 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ18reduce_interleavedPKfPfE3buf to ptr), i64 0, i64 %idxprom7, !dbg !39
  %3 = load float, ptr %arrayidx8, align 4, !dbg !39, !tbaa !28
  %4 = load float, ptr %arrayidx3, align 4, !dbg !40, !tbaa !28
  %add11 = fadd contract float %3, %4, !dbg !40
  store float %add11, ptr %arrayidx3, align 4, !dbg !40, !tbaa !28
  br label %if.end, !dbg !41

if.end:                                           ; preds = %if.then, %entry
  tail call void @llvm.nvvm.barrier0(), !dbg !42
  %rem.1 = and i32 %0, 3, !dbg !35
  %cmp5.1 = icmp eq i32 %rem.1, 0, !dbg !36
  br i1 %cmp5.1, label %if.then.1, label %if.end.1, !dbg !37

if.then.1:                                        ; preds = %if.end
  %add6.1 = add nuw i32 %0, 2, !dbg !38
  %idxprom7.1 = zext i32 %add6.1 to i64, !dbg !39
  %arrayidx8.1 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ18reduce_interleavedPKfPfE3buf to ptr), i64 0, i64 %idxprom7.1, !dbg !39
  %5 = load float, ptr %arrayidx8.1, align 4, !dbg !39, !tbaa !28
  %6 = load float, ptr %arrayidx3, align 4, !dbg !40, !tbaa !28
  %add11.1 = fadd contract float %5, %6, !dbg !40
  store float %add11.1, ptr %arrayidx3, align 4, !dbg !40, !tbaa !28
  br label %if.end.1, !dbg !41

if.end.1:                                         ; preds = %if.then.1, %if.end
  tail call void @llvm.nvvm.barrier0(), !dbg !42
  %rem.2 = and i32 %0, 7, !dbg !35
  %cmp5.2 = icmp eq i32 %rem.2, 0, !dbg !36
  br i1 %cmp5.2, label %if.then.2, label %if.end.2, !dbg !37

if.then.2:                                        ; preds = %if.end.1
  %add6.2 = add nuw i32 %0, 4, !dbg !38
  %idxprom7.2 = zext i32 %add6.2 to i64, !dbg !39
  %arrayidx8.2 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ18reduce_interleavedPKfPfE3buf to ptr), i64 0, i64 %idxprom7.2, !dbg !39
  %7 = load float, ptr %arrayidx8.2, align 4, !dbg !39, !tbaa !28
  %8 = load float, ptr %arrayidx3, align 4, !dbg !40, !tbaa !28
  %add11.2 = fadd contract float %7, %8, !dbg !40
  store float %add11.2, ptr %arrayidx3, align 4, !dbg !40, !tbaa !28
  br label %if.end.2, !dbg !41

if.end.2:                                         ; preds = %if.then.2, %if.end.1
  tail call void @llvm.nvvm.barrier0(), !dbg !42
  %rem.3 = and i32 %0, 15, !dbg !35
  %cmp5.3 = icmp eq i32 %rem.3, 0, !dbg !36
  br i1 %cmp5.3, label %if.then.3, label %if.end.3, !dbg !37

if.then.3:                                        ; preds = %if.end.2
  %add6.3 = add nuw i32 %0, 8, !dbg !38
  %idxprom7.3 = zext i32 %add6.3 to i64, !dbg !39
  %arrayidx8.3 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ18reduce_interleavedPKfPfE3buf to ptr), i64 0, i64 %idxprom7.3, !dbg !39
  %9 = load float, ptr %arrayidx8.3, align 4, !dbg !39, !tbaa !28
  %10 = load float, ptr %arrayidx3, align 4, !dbg !40, !tbaa !28
  %add11.3 = fadd contract float %9, %10, !dbg !40
  store float %add11.3, ptr %arrayidx3, align 4, !dbg !40, !tbaa !28
  br label %if.end.3, !dbg !41

if.end.3:                                         ; preds = %if.then.3, %if.end.2
  tail call void @llvm.nvvm.barrier0(), !dbg !42
  %rem.4 = and i32 %0, 31, !dbg !35
  %cmp5.4 = icmp eq i32 %rem.4, 0, !dbg !36
  br i1 %cmp5.4, label %if.then.4, label %if.end.4, !dbg !37

if.then.4:                                        ; preds = %if.end.3
  %add6.4 = add nuw i32 %0, 16, !dbg !38
  %idxprom7.4 = zext i32 %add6.4 to i64, !dbg !39
  %arrayidx8.4 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ18reduce_interleavedPKfPfE3buf to ptr), i64 0, i64 %idxprom7.4, !dbg !39
  %11 = load float, ptr %arrayidx8.4, align 4, !dbg !39, !tbaa !28
  %12 = load float, ptr %arrayidx3, align 4, !dbg !40, !tbaa !28
  %add11.4 = fadd contract float %11, %12, !dbg !40
  store float %add11.4, ptr %arrayidx3, align 4, !dbg !40, !tbaa !28
  br label %if.end.4, !dbg !41

if.end.4:                                         ; preds = %if.then.4, %if.end.3
  tail call void @llvm.nvvm.barrier0(), !dbg !42
  %rem.5 = and i32 %0, 63, !dbg !35
  %cmp5.5 = icmp eq i32 %rem.5, 0, !dbg !36
  br i1 %cmp5.5, label %if.then.5, label %if.end.5, !dbg !37

if.then.5:                                        ; preds = %if.end.4
  %add6.5 = add nuw i32 %0, 32, !dbg !38
  %idxprom7.5 = zext i32 %add6.5 to i64, !dbg !39
  %arrayidx8.5 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ18reduce_interleavedPKfPfE3buf to ptr), i64 0, i64 %idxprom7.5, !dbg !39
  %13 = load float, ptr %arrayidx8.5, align 4, !dbg !39, !tbaa !28
  %14 = load float, ptr %arrayidx3, align 4, !dbg !40, !tbaa !28
  %add11.5 = fadd contract float %13, %14, !dbg !40
  store float %add11.5, ptr %arrayidx3, align 4, !dbg !40, !tbaa !28
  br label %if.end.5, !dbg !41

if.end.5:                                         ; preds = %if.then.5, %if.end.4
  tail call void @llvm.nvvm.barrier0(), !dbg !42
  %rem.6 = and i32 %0, 127, !dbg !35
  %cmp5.6 = icmp eq i32 %rem.6, 0, !dbg !36
  br i1 %cmp5.6, label %if.then.6, label %if.end.6, !dbg !37

if.then.6:                                        ; preds = %if.end.5
  %add6.6 = add nuw i32 %0, 64, !dbg !38
  %idxprom7.6 = zext i32 %add6.6 to i64, !dbg !39
  %arrayidx8.6 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ18reduce_interleavedPKfPfE3buf to ptr), i64 0, i64 %idxprom7.6, !dbg !39
  %15 = load float, ptr %arrayidx8.6, align 4, !dbg !39, !tbaa !28
  %16 = load float, ptr %arrayidx3, align 4, !dbg !40, !tbaa !28
  %add11.6 = fadd contract float %15, %16, !dbg !40
  store float %add11.6, ptr %arrayidx3, align 4, !dbg !40, !tbaa !28
  br label %if.end.6, !dbg !41

if.end.6:                                         ; preds = %if.then.6, %if.end.5
  tail call void @llvm.nvvm.barrier0(), !dbg !42
  %rem.7 = and i32 %0, 255, !dbg !35
  %cmp5.7 = icmp eq i32 %rem.7, 0, !dbg !36
  br i1 %cmp5.7, label %if.then.7, label %if.end.7, !dbg !37

if.then.7:                                        ; preds = %if.end.6
  %add6.7 = add nuw i32 %0, 128, !dbg !38
  %idxprom7.7 = zext i32 %add6.7 to i64, !dbg !39
  %arrayidx8.7 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ18reduce_interleavedPKfPfE3buf to ptr), i64 0, i64 %idxprom7.7, !dbg !39
  %17 = load float, ptr %arrayidx8.7, align 4, !dbg !39, !tbaa !28
  %18 = load float, ptr %arrayidx3, align 4, !dbg !40, !tbaa !28
  %add11.7 = fadd contract float %17, %18, !dbg !40
  store float %add11.7, ptr %arrayidx3, align 4, !dbg !40, !tbaa !28
  br label %if.end.7, !dbg !41

if.end.7:                                         ; preds = %if.then.7, %if.end.6
  tail call void @llvm.nvvm.barrier0(), !dbg !42
  %cmp13 = icmp eq i32 %0, 0, !dbg !43
  br i1 %cmp13, label %if.then14, label %if.end18, !dbg !44

if.then14:                                        ; preds = %if.end.7
  %idxprom16 = zext i32 %1 to i64, !dbg !45
  %arrayidx17 = getelementptr inbounds float, ptr %out, i64 %idxprom16, !dbg !45
  %19 = load float, ptr addrspacecast (ptr addrspace(3) @_ZZ18reduce_interleavedPKfPfE3buf to ptr), align 4, !dbg !46, !tbaa !28
  store float %19, ptr %arrayidx17, align 4, !dbg !47, !tbaa !28
  br label %if.end18, !dbg !45

if.end18:                                         ; preds = %if.then14, %if.end.7
  ret void, !dbg !48
}

; Function Attrs: convergent nocallback nounwind
declare void @llvm.nvvm.barrier0() #1

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z17reduce_sequentialPKfPf(ptr nocapture noundef readonly %in, ptr nocapture noundef writeonly %out) local_unnamed_addr #0 !dbg !49 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !50
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !52
  %mul = shl i32 %1, 8, !dbg !54
  %add = add i32 %mul, %0, !dbg !55
  %idxprom = zext i32 %add to i64, !dbg !56
  %arrayidx = getelementptr inbounds float, ptr %in, i64 %idxprom, !dbg !56
  %2 = load float, ptr %arrayidx, align 4, !dbg !56, !tbaa !28
  %idxprom2 = zext i32 %0 to i64, !dbg !57
  %arrayidx3 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ17reduce_sequentialPKfPfE3buf to ptr), i64 0, i64 %idxprom2, !dbg !57
  store float %2, ptr %arrayidx3, align 4, !dbg !58, !tbaa !28
  tail call void @llvm.nvvm.barrier0(), !dbg !59
  %cmp4 = icmp ult i32 %0, 128, !dbg !60
  br i1 %cmp4, label %if.then, label %if.end, !dbg !61

if.then:                                          ; preds = %entry
  %add5 = add nuw nsw i32 %0, 128, !dbg !62
  %idxprom6 = zext i32 %add5 to i64, !dbg !63
  %arrayidx7 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ17reduce_sequentialPKfPfE3buf to ptr), i64 0, i64 %idxprom6, !dbg !63
  %3 = load float, ptr %arrayidx7, align 4, !dbg !63, !tbaa !28
  %4 = load float, ptr %arrayidx3, align 4, !dbg !64, !tbaa !28
  %add10 = fadd contract float %3, %4, !dbg !64
  store float %add10, ptr %arrayidx3, align 4, !dbg !64, !tbaa !28
  br label %if.end, !dbg !65

if.end:                                           ; preds = %if.then, %entry
  tail call void @llvm.nvvm.barrier0(), !dbg !66
  %cmp4.1 = icmp ult i32 %0, 64, !dbg !60
  br i1 %cmp4.1, label %if.then.1, label %if.end.1, !dbg !61

if.then.1:                                        ; preds = %if.end
  %add5.1 = add nuw nsw i32 %0, 64, !dbg !62
  %idxprom6.1 = zext i32 %add5.1 to i64, !dbg !63
  %arrayidx7.1 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ17reduce_sequentialPKfPfE3buf to ptr), i64 0, i64 %idxprom6.1, !dbg !63
  %5 = load float, ptr %arrayidx7.1, align 4, !dbg !63, !tbaa !28
  %6 = load float, ptr %arrayidx3, align 4, !dbg !64, !tbaa !28
  %add10.1 = fadd contract float %5, %6, !dbg !64
  store float %add10.1, ptr %arrayidx3, align 4, !dbg !64, !tbaa !28
  br label %if.end.1, !dbg !65

if.end.1:                                         ; preds = %if.then.1, %if.end
  tail call void @llvm.nvvm.barrier0(), !dbg !66
  %cmp4.2 = icmp ult i32 %0, 32, !dbg !60
  br i1 %cmp4.2, label %if.then.2, label %if.end.2, !dbg !61

if.then.2:                                        ; preds = %if.end.1
  %add5.2 = add nuw nsw i32 %0, 32, !dbg !62
  %idxprom6.2 = zext i32 %add5.2 to i64, !dbg !63
  %arrayidx7.2 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ17reduce_sequentialPKfPfE3buf to ptr), i64 0, i64 %idxprom6.2, !dbg !63
  %7 = load float, ptr %arrayidx7.2, align 4, !dbg !63, !tbaa !28
  %8 = load float, ptr %arrayidx3, align 4, !dbg !64, !tbaa !28
  %add10.2 = fadd contract float %7, %8, !dbg !64
  store float %add10.2, ptr %arrayidx3, align 4, !dbg !64, !tbaa !28
  br label %if.end.2, !dbg !65

if.end.2:                                         ; preds = %if.then.2, %if.end.1
  tail call void @llvm.nvvm.barrier0(), !dbg !66
  %cmp4.3 = icmp ult i32 %0, 16, !dbg !60
  br i1 %cmp4.3, label %if.then.3, label %if.end.3, !dbg !61

if.then.3:                                        ; preds = %if.end.2
  %add5.3 = add nuw nsw i32 %0, 16, !dbg !62
  %idxprom6.3 = zext i32 %add5.3 to i64, !dbg !63
  %arrayidx7.3 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ17reduce_sequentialPKfPfE3buf to ptr), i64 0, i64 %idxprom6.3, !dbg !63
  %9 = load float, ptr %arrayidx7.3, align 4, !dbg !63, !tbaa !28
  %10 = load float, ptr %arrayidx3, align 4, !dbg !64, !tbaa !28
  %add10.3 = fadd contract float %9, %10, !dbg !64
  store float %add10.3, ptr %arrayidx3, align 4, !dbg !64, !tbaa !28
  br label %if.end.3, !dbg !65

if.end.3:                                         ; preds = %if.then.3, %if.end.2
  tail call void @llvm.nvvm.barrier0(), !dbg !66
  %cmp4.4 = icmp ult i32 %0, 8, !dbg !60
  br i1 %cmp4.4, label %if.then.4, label %if.end.4, !dbg !61

if.then.4:                                        ; preds = %if.end.3
  %add5.4 = add nuw nsw i32 %0, 8, !dbg !62
  %idxprom6.4 = zext i32 %add5.4 to i64, !dbg !63
  %arrayidx7.4 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ17reduce_sequentialPKfPfE3buf to ptr), i64 0, i64 %idxprom6.4, !dbg !63
  %11 = load float, ptr %arrayidx7.4, align 4, !dbg !63, !tbaa !28
  %12 = load float, ptr %arrayidx3, align 4, !dbg !64, !tbaa !28
  %add10.4 = fadd contract float %11, %12, !dbg !64
  store float %add10.4, ptr %arrayidx3, align 4, !dbg !64, !tbaa !28
  br label %if.end.4, !dbg !65

if.end.4:                                         ; preds = %if.then.4, %if.end.3
  tail call void @llvm.nvvm.barrier0(), !dbg !66
  %cmp4.5 = icmp ult i32 %0, 4, !dbg !60
  br i1 %cmp4.5, label %if.then.5, label %if.end.5, !dbg !61

if.then.5:                                        ; preds = %if.end.4
  %add5.5 = add nuw nsw i32 %0, 4, !dbg !62
  %idxprom6.5 = zext i32 %add5.5 to i64, !dbg !63
  %arrayidx7.5 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ17reduce_sequentialPKfPfE3buf to ptr), i64 0, i64 %idxprom6.5, !dbg !63
  %13 = load float, ptr %arrayidx7.5, align 4, !dbg !63, !tbaa !28
  %14 = load float, ptr %arrayidx3, align 4, !dbg !64, !tbaa !28
  %add10.5 = fadd contract float %13, %14, !dbg !64
  store float %add10.5, ptr %arrayidx3, align 4, !dbg !64, !tbaa !28
  br label %if.end.5, !dbg !65

if.end.5:                                         ; preds = %if.then.5, %if.end.4
  tail call void @llvm.nvvm.barrier0(), !dbg !66
  %cmp4.6 = icmp ult i32 %0, 2, !dbg !60
  br i1 %cmp4.6, label %if.then.6, label %if.end.6, !dbg !61

if.then.6:                                        ; preds = %if.end.5
  %add5.6 = add nuw nsw i32 %0, 2, !dbg !62
  %idxprom6.6 = zext i32 %add5.6 to i64, !dbg !63
  %arrayidx7.6 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ17reduce_sequentialPKfPfE3buf to ptr), i64 0, i64 %idxprom6.6, !dbg !63
  %15 = load float, ptr %arrayidx7.6, align 4, !dbg !63, !tbaa !28
  %16 = load float, ptr %arrayidx3, align 4, !dbg !64, !tbaa !28
  %add10.6 = fadd contract float %15, %16, !dbg !64
  store float %add10.6, ptr %arrayidx3, align 4, !dbg !64, !tbaa !28
  br label %if.end.6, !dbg !65

if.end.6:                                         ; preds = %if.then.6, %if.end.5
  tail call void @llvm.nvvm.barrier0(), !dbg !66
  %cmp4.7 = icmp eq i32 %0, 0, !dbg !60
  br i1 %cmp4.7, label %if.then.7, label %if.end.7, !dbg !61

if.then.7:                                        ; preds = %if.end.6
  %add5.7 = add nuw nsw i32 %0, 1, !dbg !62
  %idxprom6.7 = zext i32 %add5.7 to i64, !dbg !63
  %arrayidx7.7 = getelementptr inbounds [256 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ17reduce_sequentialPKfPfE3buf to ptr), i64 0, i64 %idxprom6.7, !dbg !63
  %17 = load float, ptr %arrayidx7.7, align 4, !dbg !63, !tbaa !28
  %18 = load float, ptr %arrayidx3, align 4, !dbg !64, !tbaa !28
  %add10.7 = fadd contract float %17, %18, !dbg !64
  store float %add10.7, ptr %arrayidx3, align 4, !dbg !64, !tbaa !28
  br label %if.end.7, !dbg !65

if.end.7:                                         ; preds = %if.then.7, %if.end.6
  tail call void @llvm.nvvm.barrier0(), !dbg !66
  %cmp11 = icmp eq i32 %0, 0, !dbg !67
  br i1 %cmp11, label %if.then12, label %if.end16, !dbg !68

if.then12:                                        ; preds = %if.end.7
  %idxprom14 = zext i32 %1 to i64, !dbg !69
  %arrayidx15 = getelementptr inbounds float, ptr %out, i64 %idxprom14, !dbg !69
  %19 = load float, ptr addrspacecast (ptr addrspace(3) @_ZZ17reduce_sequentialPKfPfE3buf to ptr), align 4, !dbg !70, !tbaa !28
  store float %19, ptr %arrayidx15, align 4, !dbg !71, !tbaa !28
  br label %if.end16, !dbg !69

if.end16:                                         ; preds = %if.then12, %if.end.7
  ret void, !dbg !72
}

; Function Attrs: argmemonly mustprogress nofree norecurse nosync nounwind
define dso_local void @_Z15spmv_csr_scalarPKiS0_PKfS2_Pfi(ptr nocapture noundef readonly %rowStart, ptr nocapture noundef readonly %col, ptr nocapture noundef readonly %val, ptr nocapture noundef readonly %x, ptr nocapture noundef writeonly %y, i32 noundef %rows) local_unnamed_addr #2 !dbg !73 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !74
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !76
  %mul = mul i32 %0, %1, !dbg !79
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !80
  %add = add i32 %mul, %2, !dbg !82
  %cmp = icmp slt i32 %add, %rows, !dbg !83
  br i1 %cmp, label %if.then, label %if.end, !dbg !84

if.then:                                          ; preds = %entry
  %idxprom = sext i32 %add to i64, !dbg !85
  %arrayidx = getelementptr inbounds i32, ptr %rowStart, i64 %idxprom, !dbg !85
  %3 = load i32, ptr %arrayidx, align 4, !dbg !85, !tbaa !86
  %add3 = add nsw i32 %add, 1
  %idxprom4 = sext i32 %add3 to i64
  %arrayidx5 = getelementptr inbounds i32, ptr %rowStart, i64 %idxprom4
  %4 = load i32, ptr %arrayidx5, align 4, !tbaa !86
  %cmp625 = icmp sgt i32 %4, %3, !dbg !88
  br i1 %cmp625, label %for.body.preheader, label %for.cond.cleanup, !dbg !89

for.body.preheader:                               ; preds = %if.then
  %5 = sub i32 %4, %3, !dbg !89
  %.neg = add i32 %3, 1, !dbg !89
  %xtraiter = and i32 %5, 1, !dbg !89
  %lcmp.mod.not = icmp eq i32 %xtraiter, 0, !dbg !89
  br i1 %lcmp.mod.not, label %for.body.prol.loopexit, label %for.body.prol, !dbg !89

for.body.prol:                                    ; preds = %for.body.preheader
  %idxprom7.prol = sext i32 %3 to i64, !dbg !90
  %arrayidx8.prol = getelementptr inbounds float, ptr %val, i64 %idxprom7.prol, !dbg !90
  %6 = load float, ptr %arrayidx8.prol, align 4, !dbg !90, !tbaa !28
  %arrayidx10.prol = getelementptr inbounds i32, ptr %col, i64 %idxprom7.prol, !dbg !91
  %7 = load i32, ptr %arrayidx10.prol, align 4, !dbg !91, !tbaa !86
  %idxprom11.prol = sext i32 %7 to i64, !dbg !92
  %arrayidx12.prol = getelementptr inbounds float, ptr %x, i64 %idxprom11.prol, !dbg !92
  %8 = load float, ptr %arrayidx12.prol, align 4, !dbg !92, !tbaa !28
  %mul13.prol = fmul contract float %6, %8, !dbg !93
  %add14.prol = fadd contract float %mul13.prol, 0.000000e+00, !dbg !94
  %inc.prol = add nsw i32 %3, 1, !dbg !95
  br label %for.body.prol.loopexit, !dbg !89

for.body.prol.loopexit:                           ; preds = %for.body.prol, %for.body.preheader
  %add14.lcssa.unr = phi float [ undef, %for.body.preheader ], [ %add14.prol, %for.body.prol ]
  %k.027.unr = phi i32 [ %3, %for.body.preheader ], [ %inc.prol, %for.body.prol ]
  %sum.026.unr = phi float [ 0.000000e+00, %for.body.preheader ], [ %add14.prol, %for.body.prol ]
  %9 = icmp eq i32 %4, %.neg, !dbg !89
  br i1 %9, label %for.cond.cleanup, label %for.body, !dbg !89

for.cond.cleanup:                                 ; preds = %for.body.prol.loopexit, %for.body, %if.then
  %sum.0.lcssa = phi float [ 0.000000e+00, %if.then ], [ %add14.lcssa.unr, %for.body.prol.loopexit ], [ %add14.1, %for.body ], !dbg !96
  %arrayidx16 = getelementptr inbounds float, ptr %y, i64 %idxprom, !dbg !97
  store float %sum.0.lcssa, ptr %arrayidx16, align 4, !dbg !98, !tbaa !28
  br label %if.end, !dbg !99

for.body:                                         ; preds = %for.body.prol.loopexit, %for.body
  %k.027 = phi i32 [ %inc.1, %for.body ], [ %k.027.unr, %for.body.prol.loopexit ]
  %sum.026 = phi float [ %add14.1, %for.body ], [ %sum.026.unr, %for.body.prol.loopexit ]
  %idxprom7 = sext i32 %k.027 to i64, !dbg !90
  %arrayidx8 = getelementptr inbounds float, ptr %val, i64 %idxprom7, !dbg !90
  %10 = load float, ptr %arrayidx8, align 4, !dbg !90, !tbaa !28
  %arrayidx10 = getelementptr inbounds i32, ptr %col, i64 %idxprom7, !dbg !91
  %11 = load i32, ptr %arrayidx10, align 4, !dbg !91, !tbaa !86
  %idxprom11 = sext i32 %11 to i64, !dbg !92
  %arrayidx12 = getelementptr inbounds float, ptr %x, i64 %idxprom11, !dbg !92
  %12 = load float, ptr %arrayidx12, align 4, !dbg !92, !tbaa !28
  %mul13 = fmul contract float %10, %12, !dbg !93
  %add14 = fadd contract float %sum.026, %mul13, !dbg !94
  %inc = add nsw i32 %k.027, 1, !dbg !95
  %idxprom7.1 = sext i32 %inc to i64, !dbg !90
  %arrayidx8.1 = getelementptr inbounds float, ptr %val, i64 %idxprom7.1, !dbg !90
  %13 = load float, ptr %arrayidx8.1, align 4, !dbg !90, !tbaa !28
  %arrayidx10.1 = getelementptr inbounds i32, ptr %col, i64 %idxprom7.1, !dbg !91
  %14 = load i32, ptr %arrayidx10.1, align 4, !dbg !91, !tbaa !86
  %idxprom11.1 = sext i32 %14 to i64, !dbg !92
  %arrayidx12.1 = getelementptr inbounds float, ptr %x, i64 %idxprom11.1, !dbg !92
  %15 = load float, ptr %arrayidx12.1, align 4, !dbg !92, !tbaa !28
  %mul13.1 = fmul contract float %13, %15, !dbg !93
  %add14.1 = fadd contract float %add14, %mul13.1, !dbg !94
  %inc.1 = add nsw i32 %k.027, 2, !dbg !95
  %exitcond.not.1 = icmp eq i32 %inc.1, %4, !dbg !88
  br i1 %exitcond.not.1, label %for.cond.cleanup, label %for.body, !dbg !89, !llvm.loop !100

if.end:                                           ; preds = %for.cond.cleanup, %entry
  ret void, !dbg !103
}

; Function Attrs: argmemonly mustprogress nofree norecurse nosync nounwind willreturn
define dso_local void @_Z15odd_even_selectPfi(ptr nocapture noundef %a, i32 noundef %n) local_unnamed_addr #3 !dbg !104 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !105
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !107
  %mul = mul i32 %0, %1, !dbg !109
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !110
  %add = add i32 %mul, %2, !dbg !112
  %cmp.not = icmp slt i32 %add, %n, !dbg !113
  br i1 %cmp.not, label %if.end, label %cleanup, !dbg !114

if.end:                                           ; preds = %entry
  %rem = and i32 %2, 1, !dbg !115
  %cmp4 = icmp eq i32 %rem, 0, !dbg !116
  %idxprom = sext i32 %add to i64, !dbg !117
  %arrayidx = getelementptr inbounds float, ptr %a, i64 %idxprom, !dbg !117
  %3 = load float, ptr %arrayidx, align 4, !dbg !117, !tbaa !28
  %mul6 = fmul contract float %3, 2.000000e+00, !dbg !118
  %add11 = fadd contract float %3, 1.000000e+00, !dbg !118
  %mul6.sink = select i1 %cmp4, float %mul6, float %add11, !dbg !118
  store float %mul6.sink, ptr %arrayidx, align 4, !dbg !117, !tbaa !28
  br label %cleanup, !dbg !119

cleanup:                                          ; preds = %if.end, %entry
  ret void, !dbg !119
}

; Function Attrs: argmemonly mustprogress nofree norecurse nosync nounwind willreturn
define dso_local void @_Z15odd_even_branchPfS_i(ptr nocapture noundef %a, ptr nocapture noundef %b, i32 noundef %n) local_unnamed_addr #3 !dbg !120 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !121
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !123
  %mul = mul i32 %0, %1, !dbg !125
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !126
  %add = add i32 %mul, %2, !dbg !128
  %cmp.not = icmp slt i32 %add, %n, !dbg !129
  br i1 %cmp.not, label %if.end, label %cleanup, !dbg !130

if.end:                                           ; preds = %entry
  %rem = and i32 %2, 1, !dbg !131
  %cmp4 = icmp eq i32 %rem, 0, !dbg !132
  %idxprom = sext i32 %add to i64, !dbg !133
  br i1 %cmp4, label %if.then5, label %if.else, !dbg !134

if.then5:                                         ; preds = %if.end
  %arrayidx = getelementptr inbounds float, ptr %a, i64 %idxprom, !dbg !135
  %3 = load float, ptr %arrayidx, align 4, !dbg !136, !tbaa !28
  %mul6 = fmul contract float %3, 2.000000e+00, !dbg !136
  store float %mul6, ptr %arrayidx, align 4, !dbg !136, !tbaa !28
  br label %cleanup, !dbg !135

if.else:                                          ; preds = %if.end
  %arrayidx8 = getelementptr inbounds float, ptr %b, i64 %idxprom, !dbg !137
  %4 = load float, ptr %arrayidx8, align 4, !dbg !138, !tbaa !28
  %add9 = fadd contract float %4, 1.000000e+00, !dbg !138
  store float %add9, ptr %arrayidx8, align 4, !dbg !138, !tbaa !28
  br label %cleanup

cleanup:                                          ; preds = %if.then5, %if.else, %entry
  ret void, !dbg !139
}

; Function Attrs: argmemonly mustprogress nofree norecurse nosync nounwind willreturn
define dso_local void @_Z12uniform_flagPKiPfi(ptr nocapture noundef readonly %flag, ptr nocapture noundef writeonly %a, i32 noundef %n) local_unnamed_addr #3 !dbg !140 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !141
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !143
  %mul = mul i32 %0, %1, !dbg !145
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !146
  %add = add i32 %mul, %2, !dbg !148
  %cmp = icmp slt i32 %add, %n, !dbg !149
  br i1 %cmp, label %land.lhs.true, label %if.end, !dbg !150

land.lhs.true:                                    ; preds = %entry
  %3 = load i32, ptr %flag, align 4, !dbg !151, !tbaa !86
  %tobool.not = icmp eq i32 %3, 0, !dbg !151
  br i1 %tobool.not, label %if.end, label %if.then, !dbg !152

if.then:                                          ; preds = %land.lhs.true
  %idxprom = sext i32 %add to i64, !dbg !153
  %arrayidx = getelementptr inbounds float, ptr %a, i64 %idxprom, !dbg !153
  store float 0.000000e+00, ptr %arrayidx, align 4, !dbg !154, !tbaa !28
  br label %if.end, !dbg !153

if.end:                                           ; preds = %if.then, %land.lhs.true, %entry
  ret void, !dbg !155
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.tid.x() #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #4

attributes #0 = { convergent mustprogress norecurse nounwind "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_70" "target-features"="+ptx42,+sm_70" }
attributes #1 = { convergent nocallback nounwind }
attributes #2 = { argmemonly mustprogress nofree norecurse nosync nounwind "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_70" "target-features"="+ptx42,+sm_70" }
attributes #3 = { argmemonly mustprogress nofree norecurse nosync nounwind willreturn "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_70" "target-features"="+ptx42,+sm_70" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5}
!llvm.dbg.cu = !{!6}
!nvvm.annotations = !{!8, !9, !10, !11, !12, !13}
!llvm.ident = !{!14}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 2]}
!1 = !{i32 7, !"Dwarf Version", i32 2}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !7, producer: "Homebrew clang version 15.0.7", isOptimized: true, runtimeVersion: 0, emissionKind: DebugDirectivesOnly, splitDebugInlining: false, nameTableKind: None)
!7 = !DIFile(filename: "gpu_divergence.cu", directory: ".")
!8 = !{ptr @_Z18reduce_interleavedPKfPf, !"kernel", i32 1}
!9 = !{ptr @_Z17reduce_sequentialPKfPf, !"kernel", i32 1}
!10 = !{ptr @_Z15spmv_csr_scalarPKiS0_PKfS2_Pfi, !"kernel", i32 1}
!11 = !{ptr @_Z15odd_even_selectPfi, !"kernel", i32 1}
!12 = !{ptr @_Z15odd_even_branchPfS_i, !"kernel", i32 1}
!13 = !{ptr @_Z12uniform_flagPKiPfi, !"kernel", i32 1}
!14 = !{!"Homebrew clang version 15.0.7"}
!15 = distinct !DISubprogram(name: "reduce_interleaved", scope: !7, file: !7, line: 5, type: !16, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !17)
!16 = !DISubroutineType(types: !17)
!17 = !{}
!18 = !DILocation(line: 53, column: 3, scope: !19, inlinedAt: !21)
!19 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !20, file: !20, line: 53, type: !16, scopeLine: 53, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !17)
!20 = !DIFile(filename: "/opt/homebrew/Cellar/llvm@15/15.0.7/lib/clang/15.0.7/include/__clang_cuda_builtin_vars.h", directory: "")
!21 = distinct !DILocation(line: 7, column: 18, scope: !15)
!22 = !DILocation(line: 66, column: 3, scope: !23, inlinedAt: !24)
!23 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !20, file: !20, line: 66, type: !16, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !17)
!24 = distinct !DILocation(line: 8, column: 17, scope: !15)
!25 = !DILocation(line: 8, column: 28, scope: !15)
!26 = !DILocation(line: 8, column: 34, scope: !15)
!27 = !DILocation(line: 8, column: 14, scope: !15)
!28 = !{!29, !29, i64 0}
!29 = !{!"float", !30, i64 0}
!30 = !{!"omnipotent char", !31, i64 0}
!31 = !{!"Simple C++ TBAA"}
!32 = !DILocation(line: 8, column: 3, scope: !15)
!33 = !DILocation(line: 8, column: 12, scope: !15)
!34 = !DILocation(line: 9, column: 3, scope: !15)
!35 = !DILocation(line: 11, column: 13, scope: !15)
!36 = !DILocation(line: 11, column: 23, scope: !15)
!37 = !DILocation(line: 11, column: 9, scope: !15)
!38 = !DILocation(line: 12, column: 27, scope: !15)
!39 = !DILocation(line: 12, column: 19, scope: !15)
!40 = !DILocation(line: 12, column: 16, scope: !15)
!41 = !DILocation(line: 12, column: 7, scope: !15)
!42 = !DILocation(line: 13, column: 5, scope: !15)
!43 = !DILocation(line: 15, column: 11, scope: !15)
!44 = !DILocation(line: 15, column: 7, scope: !15)
!45 = !DILocation(line: 16, column: 5, scope: !15)
!46 = !DILocation(line: 16, column: 23, scope: !15)
!47 = !DILocation(line: 16, column: 21, scope: !15)
!48 = !DILocation(line: 17, column: 1, scope: !15)
!49 = distinct !DISubprogram(name: "reduce_sequential", scope: !7, file: !7, line: 20, type: !16, scopeLine: 20, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !17)
!50 = !DILocation(line: 53, column: 3, scope: !19, inlinedAt: !51)
!51 = distinct !DILocation(line: 22, column: 18, scope: !49)
!52 = !DILocation(line: 66, column: 3, scope: !23, inlinedAt: !53)
!53 = distinct !DILocation(line: 23, column: 17, scope: !49)
!54 = !DILocation(line: 23, column: 28, scope: !49)
!55 = !DILocation(line: 23, column: 34, scope: !49)
!56 = !DILocation(line: 23, column: 14, scope: !49)
!57 = !DILocation(line: 23, column: 3, scope: !49)
!58 = !DILocation(line: 23, column: 12, scope: !49)
!59 = !DILocation(line: 24, column: 3, scope: !49)
!60 = !DILocation(line: 26, column: 13, scope: !49)
!61 = !DILocation(line: 26, column: 9, scope: !49)
!62 = !DILocation(line: 27, column: 27, scope: !49)
!63 = !DILocation(line: 27, column: 19, scope: !49)
!64 = !DILocation(line: 27, column: 16, scope: !49)
!65 = !DILocation(line: 27, column: 7, scope: !49)
!66 = !DILocation(line: 28, column: 5, scope: !49)
!67 = !DILocation(line: 30, column: 11, scope: !49)
!68 = !DILocation(line: 30, column: 7, scope: !49)
!69 = !DILocation(line: 31, column: 5, scope: !49)
!70 = !DILocation(line: 31, column: 23, scope: !49)
!71 = !DILocation(line: 31, column: 21, scope: !49)
!72 = !DILocation(line: 32, column: 1, scope: !49)
!73 = distinct !DISubprogram(name: "spmv_csr_scalar", scope: !7, file: !7, line: 36, type: !16, scopeLine: 38, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !17)
!74 = !DILocation(line: 66, column: 3, scope: !23, inlinedAt: !75)
!75 = distinct !DILocation(line: 39, column: 13, scope: !73)
!76 = !DILocation(line: 79, column: 3, scope: !77, inlinedAt: !78)
!77 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !20, file: !20, line: 79, type: !16, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !17)
!78 = distinct !DILocation(line: 39, column: 26, scope: !73)
!79 = !DILocation(line: 39, column: 24, scope: !73)
!80 = !DILocation(line: 53, column: 3, scope: !19, inlinedAt: !81)
!81 = distinct !DILocation(line: 39, column: 39, scope: !73)
!82 = !DILocation(line: 39, column: 37, scope: !73)
!83 = !DILocation(line: 40, column: 11, scope: !73)
!84 = !DILocation(line: 40, column: 7, scope: !73)
!85 = !DILocation(line: 42, column: 18, scope: !73)
!86 = !{!87, !87, i64 0}
!87 = !{!"int", !30, i64 0}
!88 = !DILocation(line: 42, column: 35, scope: !73)
!89 = !DILocation(line: 42, column: 5, scope: !73)
!90 = !DILocation(line: 43, column: 14, scope: !73)
!91 = !DILocation(line: 43, column: 25, scope: !73)
!92 = !DILocation(line: 43, column: 23, scope: !73)
!93 = !DILocation(line: 43, column: 21, scope: !73)
!94 = !DILocation(line: 43, column: 11, scope: !73)
!95 = !DILocation(line: 42, column: 56, scope: !73)
!96 = !DILocation(line: 0, scope: !73)
!97 = !DILocation(line: 44, column: 5, scope: !73)
!98 = !DILocation(line: 44, column: 12, scope: !73)
!99 = !DILocation(line: 45, column: 3, scope: !73)
!100 = distinct !{!100, !89, !101, !102}
!101 = !DILocation(line: 43, column: 31, scope: !73)
!102 = !{!"llvm.loop.mustprogress"}
!103 = !DILocation(line: 46, column: 1, scope: !73)
!104 = distinct !DISubprogram(name: "odd_even_select", scope: !7, file: !7, line: 50, type: !16, scopeLine: 50, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !17)
!105 = !DILocation(line: 66, column: 3, scope: !23, inlinedAt: !106)
!106 = distinct !DILocation(line: 51, column: 11, scope: !104)
!107 = !DILocation(line: 79, column: 3, scope: !77, inlinedAt: !108)
!108 = distinct !DILocation(line: 51, column: 24, scope: !104)
!109 = !DILocation(line: 51, column: 22, scope: !104)
!110 = !DILocation(line: 53, column: 3, scope: !19, inlinedAt: !111)
!111 = distinct !DILocation(line: 51, column: 37, scope: !104)
!112 = !DILocation(line: 51, column: 35, scope: !104)
!113 = !DILocation(line: 52, column: 9, scope: !104)
!114 = !DILocation(line: 52, column: 7, scope: !104)
!115 = !DILocation(line: 54, column: 19, scope: !104)
!116 = !DILocation(line: 54, column: 23, scope: !104)
!117 = !DILocation(line: 0, scope: !104)
!118 = !DILocation(line: 54, column: 7, scope: !104)
!119 = !DILocation(line: 58, column: 1, scope: !104)
!120 = distinct !DISubprogram(name: "odd_even_branch", scope: !7, file: !7, line: 62, type: !16, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !17)
!121 = !DILocation(line: 66, column: 3, scope: !23, inlinedAt: !122)
!122 = distinct !DILocation(line: 63, column: 11, scope: !120)
!123 = !DILocation(line: 79, column: 3, scope: !77, inlinedAt: !124)
!124 = distinct !DILocation(line: 63, column: 24, scope: !120)
!125 = !DILocation(line: 63, column: 22, scope: !120)
!126 = !DILocation(line: 53, column: 3, scope: !19, inlinedAt: !127)
!127 = distinct !DILocation(line: 63, column: 37, scope: !120)
!128 = !DILocation(line: 63, column: 35, scope: !120)
!129 = !DILocation(line: 64, column: 9, scope: !120)
!130 = !DILocation(line: 64, column: 7, scope: !120)
!131 = !DILocation(line: 66, column: 19, scope: !120)
!132 = !DILocation(line: 66, column: 23, scope: !120)
!133 = !DILocation(line: 0, scope: !120)
!134 = !DILocation(line: 66, column: 7, scope: !120)
!135 = !DILocation(line: 67, column: 5, scope: !120)
!136 = !DILocation(line: 67, column: 10, scope: !120)
!137 = !DILocation(line: 69, column: 5, scope: !120)
!138 = !DILocation(line: 69, column: 10, scope: !120)
!139 = !DILocation(line: 70, column: 1, scope: !120)
!140 = distinct !DISubprogram(name: "uniform_flag", scope: !7, file: !7, line: 74, type: !16, scopeLine: 74, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !17)
!141 = !DILocation(line: 66, column: 3, scope: !23, inlinedAt: !142)
!142 = distinct !DILocation(line: 75, column: 11, scope: !140)
!143 = !DILocation(line: 79, column: 3, scope: !77, inlinedAt: !144)
!144 = distinct !DILocation(line: 75, column: 24, scope: !140)
!145 = !DILocation(line: 75, column: 22, scope: !140)
!146 = !DILocation(line: 53, column: 3, scope: !19, inlinedAt: !147)
!147 = distinct !DILocation(line: 75, column: 37, scope: !140)
!148 = !DILocation(line: 75, column: 35, scope: !140)
!149 = !DILocation(line: 76, column: 9, scope: !140)
!150 = !DILocation(line: 76, column: 13, scope: !140)
!151 = !DILocation(line: 76, column: 16, scope: !140)
!152 = !DILocation(line: 76, column: 7, scope: !140)
!153 = !DILocation(line: 77, column: 5, scope: !140)
!154 = !DILocation(line: 77, column: 10, scope: !140)
!155 = !DILocation(line: 78, column: 1, scope: !140)
