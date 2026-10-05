; ModuleID = 'gpu_matmul.cu'
source_filename = "gpu_matmul.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

; Function Attrs: argmemonly mustprogress nofree norecurse nosync nounwind
define dso_local void @_Z6matmulPKfS0_Pfi(ptr nocapture noundef readonly %A, ptr nocapture noundef readonly %B, ptr nocapture noundef writeonly %C, i32 noundef %n) local_unnamed_addr #0 !dbg !11 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.y(), !dbg !14
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.y(), !dbg !18
  %mul = mul i32 %0, %1, !dbg !21
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.y(), !dbg !22
  %add = add i32 %mul, %2, !dbg !25
  %3 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !26
  %4 = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !29
  %mul5 = mul i32 %3, %4, !dbg !32
  %5 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !33
  %add7 = add i32 %mul5, %5, !dbg !36
  %cmp = icmp slt i32 %add, %n, !dbg !37
  %cmp8 = icmp slt i32 %add7, %n
  %or.cond = and i1 %cmp, %cmp8, !dbg !38
  br i1 %or.cond, label %for.cond.preheader, label %if.end, !dbg !38

for.cond.preheader:                               ; preds = %entry
  %cmp935 = icmp sgt i32 %n, 0, !dbg !39
  %mul10 = mul nsw i32 %add, %n
  br i1 %cmp935, label %for.body.preheader, label %for.cond.cleanup, !dbg !40

for.body.preheader:                               ; preds = %for.cond.preheader
  %xtraiter = and i32 %n, 1, !dbg !40
  %6 = icmp eq i32 %n, 1, !dbg !40
  br i1 %6, label %for.cond.cleanup.loopexit.unr-lcssa, label %for.body.preheader.new, !dbg !40

for.body.preheader.new:                           ; preds = %for.body.preheader
  %unroll_iter = and i32 %n, -2, !dbg !40
  br label %for.body, !dbg !40

for.cond.cleanup.loopexit.unr-lcssa:              ; preds = %for.body, %for.body.preheader
  %add17.lcssa.ph = phi float [ undef, %for.body.preheader ], [ %add17.1, %for.body ]
  %k.037.unr = phi i32 [ 0, %for.body.preheader ], [ %inc.1, %for.body ]
  %sum.036.unr = phi float [ 0.000000e+00, %for.body.preheader ], [ %add17.1, %for.body ]
  %lcmp.mod.not = icmp eq i32 %xtraiter, 0, !dbg !40
  br i1 %lcmp.mod.not, label %for.cond.cleanup, label %for.body.epil, !dbg !40

for.body.epil:                                    ; preds = %for.cond.cleanup.loopexit.unr-lcssa
  %add11.epil = add nsw i32 %k.037.unr, %mul10, !dbg !41
  %idxprom.epil = sext i32 %add11.epil to i64, !dbg !42
  %arrayidx.epil = getelementptr inbounds float, ptr %A, i64 %idxprom.epil, !dbg !42
  %7 = load float, ptr %arrayidx.epil, align 4, !dbg !42, !tbaa !43
  %mul12.epil = mul nsw i32 %k.037.unr, %n, !dbg !47
  %add13.epil = add nsw i32 %mul12.epil, %add7, !dbg !48
  %idxprom14.epil = sext i32 %add13.epil to i64, !dbg !49
  %arrayidx15.epil = getelementptr inbounds float, ptr %B, i64 %idxprom14.epil, !dbg !49
  %8 = load float, ptr %arrayidx15.epil, align 4, !dbg !49, !tbaa !43
  %mul16.epil = fmul contract float %7, %8, !dbg !50
  %add17.epil = fadd contract float %sum.036.unr, %mul16.epil, !dbg !51
  br label %for.cond.cleanup, !dbg !52

for.cond.cleanup:                                 ; preds = %for.body.epil, %for.cond.cleanup.loopexit.unr-lcssa, %for.cond.preheader
  %sum.0.lcssa = phi float [ 0.000000e+00, %for.cond.preheader ], [ %add17.lcssa.ph, %for.cond.cleanup.loopexit.unr-lcssa ], [ %add17.epil, %for.body.epil ], !dbg !53
  %add19 = add nsw i32 %mul10, %add7, !dbg !52
  %idxprom20 = sext i32 %add19 to i64, !dbg !54
  %arrayidx21 = getelementptr inbounds float, ptr %C, i64 %idxprom20, !dbg !54
  store float %sum.0.lcssa, ptr %arrayidx21, align 4, !dbg !55, !tbaa !43
  br label %if.end, !dbg !56

for.body:                                         ; preds = %for.body, %for.body.preheader.new
  %k.037 = phi i32 [ 0, %for.body.preheader.new ], [ %inc.1, %for.body ]
  %sum.036 = phi float [ 0.000000e+00, %for.body.preheader.new ], [ %add17.1, %for.body ]
  %niter = phi i32 [ 0, %for.body.preheader.new ], [ %niter.next.1, %for.body ]
  %add11 = add nsw i32 %k.037, %mul10, !dbg !41
  %idxprom = sext i32 %add11 to i64, !dbg !42
  %arrayidx = getelementptr inbounds float, ptr %A, i64 %idxprom, !dbg !42
  %9 = load float, ptr %arrayidx, align 4, !dbg !42, !tbaa !43
  %mul12 = mul nsw i32 %k.037, %n, !dbg !47
  %add13 = add nsw i32 %mul12, %add7, !dbg !48
  %idxprom14 = sext i32 %add13 to i64, !dbg !49
  %arrayidx15 = getelementptr inbounds float, ptr %B, i64 %idxprom14, !dbg !49
  %10 = load float, ptr %arrayidx15, align 4, !dbg !49, !tbaa !43
  %mul16 = fmul contract float %9, %10, !dbg !50
  %add17 = fadd contract float %sum.036, %mul16, !dbg !51
  %inc = or i32 %k.037, 1, !dbg !57
  %add11.1 = add nsw i32 %inc, %mul10, !dbg !41
  %idxprom.1 = sext i32 %add11.1 to i64, !dbg !42
  %arrayidx.1 = getelementptr inbounds float, ptr %A, i64 %idxprom.1, !dbg !42
  %11 = load float, ptr %arrayidx.1, align 4, !dbg !42, !tbaa !43
  %mul12.1 = mul nsw i32 %inc, %n, !dbg !47
  %add13.1 = add nsw i32 %mul12.1, %add7, !dbg !48
  %idxprom14.1 = sext i32 %add13.1 to i64, !dbg !49
  %arrayidx15.1 = getelementptr inbounds float, ptr %B, i64 %idxprom14.1, !dbg !49
  %12 = load float, ptr %arrayidx15.1, align 4, !dbg !49, !tbaa !43
  %mul16.1 = fmul contract float %11, %12, !dbg !50
  %add17.1 = fadd contract float %add17, %mul16.1, !dbg !51
  %inc.1 = add nuw nsw i32 %k.037, 2, !dbg !57
  %niter.next.1 = add i32 %niter, 2, !dbg !40
  %niter.ncmp.1 = icmp eq i32 %niter.next.1, %unroll_iter, !dbg !40
  br i1 %niter.ncmp.1, label %for.cond.cleanup.loopexit.unr-lcssa, label %for.body, !dbg !40, !llvm.loop !58

if.end:                                           ; preds = %for.cond.cleanup, %entry
  ret void, !dbg !61
}

; Function Attrs: argmemonly mustprogress nofree norecurse nosync nounwind
define dso_local void @_Z14matmul_swappedPKfS0_Pfi(ptr nocapture noundef readonly %A, ptr nocapture noundef readonly %B, ptr nocapture noundef writeonly %C, i32 noundef %n) local_unnamed_addr #0 !dbg !62 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !63
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !65
  %mul = mul i32 %0, %1, !dbg !67
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !68
  %add = add i32 %mul, %2, !dbg !70
  %3 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.y(), !dbg !71
  %4 = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.y(), !dbg !73
  %mul5 = mul i32 %3, %4, !dbg !75
  %5 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.y(), !dbg !76
  %add7 = add i32 %mul5, %5, !dbg !78
  %cmp = icmp slt i32 %add, %n, !dbg !79
  %cmp8 = icmp slt i32 %add7, %n
  %or.cond = and i1 %cmp, %cmp8, !dbg !80
  br i1 %or.cond, label %for.cond.preheader, label %if.end, !dbg !80

for.cond.preheader:                               ; preds = %entry
  %cmp935 = icmp sgt i32 %n, 0, !dbg !81
  %mul10 = mul nsw i32 %add, %n
  br i1 %cmp935, label %for.body.preheader, label %for.cond.cleanup, !dbg !82

for.body.preheader:                               ; preds = %for.cond.preheader
  %xtraiter = and i32 %n, 1, !dbg !82
  %6 = icmp eq i32 %n, 1, !dbg !82
  br i1 %6, label %for.cond.cleanup.loopexit.unr-lcssa, label %for.body.preheader.new, !dbg !82

for.body.preheader.new:                           ; preds = %for.body.preheader
  %unroll_iter = and i32 %n, -2, !dbg !82
  br label %for.body, !dbg !82

for.cond.cleanup.loopexit.unr-lcssa:              ; preds = %for.body, %for.body.preheader
  %add17.lcssa.ph = phi float [ undef, %for.body.preheader ], [ %add17.1, %for.body ]
  %k.037.unr = phi i32 [ 0, %for.body.preheader ], [ %inc.1, %for.body ]
  %sum.036.unr = phi float [ 0.000000e+00, %for.body.preheader ], [ %add17.1, %for.body ]
  %lcmp.mod.not = icmp eq i32 %xtraiter, 0, !dbg !82
  br i1 %lcmp.mod.not, label %for.cond.cleanup, label %for.body.epil, !dbg !82

for.body.epil:                                    ; preds = %for.cond.cleanup.loopexit.unr-lcssa
  %add11.epil = add nsw i32 %k.037.unr, %mul10, !dbg !83
  %idxprom.epil = sext i32 %add11.epil to i64, !dbg !84
  %arrayidx.epil = getelementptr inbounds float, ptr %A, i64 %idxprom.epil, !dbg !84
  %7 = load float, ptr %arrayidx.epil, align 4, !dbg !84, !tbaa !43
  %mul12.epil = mul nsw i32 %k.037.unr, %n, !dbg !85
  %add13.epil = add nsw i32 %mul12.epil, %add7, !dbg !86
  %idxprom14.epil = sext i32 %add13.epil to i64, !dbg !87
  %arrayidx15.epil = getelementptr inbounds float, ptr %B, i64 %idxprom14.epil, !dbg !87
  %8 = load float, ptr %arrayidx15.epil, align 4, !dbg !87, !tbaa !43
  %mul16.epil = fmul contract float %7, %8, !dbg !88
  %add17.epil = fadd contract float %sum.036.unr, %mul16.epil, !dbg !89
  br label %for.cond.cleanup, !dbg !90

for.cond.cleanup:                                 ; preds = %for.body.epil, %for.cond.cleanup.loopexit.unr-lcssa, %for.cond.preheader
  %sum.0.lcssa = phi float [ 0.000000e+00, %for.cond.preheader ], [ %add17.lcssa.ph, %for.cond.cleanup.loopexit.unr-lcssa ], [ %add17.epil, %for.body.epil ], !dbg !91
  %add19 = add nsw i32 %mul10, %add7, !dbg !90
  %idxprom20 = sext i32 %add19 to i64, !dbg !92
  %arrayidx21 = getelementptr inbounds float, ptr %C, i64 %idxprom20, !dbg !92
  store float %sum.0.lcssa, ptr %arrayidx21, align 4, !dbg !93, !tbaa !43
  br label %if.end, !dbg !94

for.body:                                         ; preds = %for.body, %for.body.preheader.new
  %k.037 = phi i32 [ 0, %for.body.preheader.new ], [ %inc.1, %for.body ]
  %sum.036 = phi float [ 0.000000e+00, %for.body.preheader.new ], [ %add17.1, %for.body ]
  %niter = phi i32 [ 0, %for.body.preheader.new ], [ %niter.next.1, %for.body ]
  %add11 = add nsw i32 %k.037, %mul10, !dbg !83
  %idxprom = sext i32 %add11 to i64, !dbg !84
  %arrayidx = getelementptr inbounds float, ptr %A, i64 %idxprom, !dbg !84
  %9 = load float, ptr %arrayidx, align 4, !dbg !84, !tbaa !43
  %mul12 = mul nsw i32 %k.037, %n, !dbg !85
  %add13 = add nsw i32 %mul12, %add7, !dbg !86
  %idxprom14 = sext i32 %add13 to i64, !dbg !87
  %arrayidx15 = getelementptr inbounds float, ptr %B, i64 %idxprom14, !dbg !87
  %10 = load float, ptr %arrayidx15, align 4, !dbg !87, !tbaa !43
  %mul16 = fmul contract float %9, %10, !dbg !88
  %add17 = fadd contract float %sum.036, %mul16, !dbg !89
  %inc = or i32 %k.037, 1, !dbg !95
  %add11.1 = add nsw i32 %inc, %mul10, !dbg !83
  %idxprom.1 = sext i32 %add11.1 to i64, !dbg !84
  %arrayidx.1 = getelementptr inbounds float, ptr %A, i64 %idxprom.1, !dbg !84
  %11 = load float, ptr %arrayidx.1, align 4, !dbg !84, !tbaa !43
  %mul12.1 = mul nsw i32 %inc, %n, !dbg !85
  %add13.1 = add nsw i32 %mul12.1, %add7, !dbg !86
  %idxprom14.1 = sext i32 %add13.1 to i64, !dbg !87
  %arrayidx15.1 = getelementptr inbounds float, ptr %B, i64 %idxprom14.1, !dbg !87
  %12 = load float, ptr %arrayidx15.1, align 4, !dbg !87, !tbaa !43
  %mul16.1 = fmul contract float %11, %12, !dbg !88
  %add17.1 = fadd contract float %add17, %mul16.1, !dbg !89
  %inc.1 = add nuw nsw i32 %k.037, 2, !dbg !95
  %niter.next.1 = add i32 %niter, 2, !dbg !82
  %niter.ncmp.1 = icmp eq i32 %niter.next.1, %unroll_iter, !dbg !82
  br i1 %niter.ncmp.1, label %for.cond.cleanup.loopexit.unr-lcssa, label %for.body, !dbg !82, !llvm.loop !96

if.end:                                           ; preds = %for.cond.cleanup, %entry
  ret void, !dbg !98
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.ctaid.y() #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.ntid.y() #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.tid.y() #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.tid.x() #1

attributes #0 = { argmemonly mustprogress nofree norecurse nosync nounwind "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_70" "target-features"="+ptx42,+sm_70" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5}
!llvm.dbg.cu = !{!6}
!nvvm.annotations = !{!8, !9}
!llvm.ident = !{!10}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 2]}
!1 = !{i32 7, !"Dwarf Version", i32 2}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !7, producer: "Homebrew clang version 15.0.7", isOptimized: true, runtimeVersion: 0, emissionKind: DebugDirectivesOnly, splitDebugInlining: false, nameTableKind: None)
!7 = !DIFile(filename: "gpu_matmul.cu", directory: ".")
!8 = !{ptr @_Z6matmulPKfS0_Pfi, !"kernel", i32 1}
!9 = !{ptr @_Z14matmul_swappedPKfS0_Pfi, !"kernel", i32 1}
!10 = !{!"Homebrew clang version 15.0.7"}
!11 = distinct !DISubprogram(name: "matmul", scope: !7, file: !7, line: 5, type: !12, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!12 = !DISubroutineType(types: !13)
!13 = !{}
!14 = !DILocation(line: 67, column: 3, scope: !15, inlinedAt: !17)
!15 = distinct !DISubprogram(name: "__fetch_builtin_y", scope: !16, file: !16, line: 67, type: !12, scopeLine: 67, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!16 = !DIFile(filename: "/opt/homebrew/Cellar/llvm@15/15.0.7/lib/clang/15.0.7/include/__clang_cuda_builtin_vars.h", directory: "")
!17 = distinct !DILocation(line: 6, column: 13, scope: !11)
!18 = !DILocation(line: 80, column: 3, scope: !19, inlinedAt: !20)
!19 = distinct !DISubprogram(name: "__fetch_builtin_y", scope: !16, file: !16, line: 80, type: !12, scopeLine: 80, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!20 = distinct !DILocation(line: 6, column: 26, scope: !11)
!21 = !DILocation(line: 6, column: 24, scope: !11)
!22 = !DILocation(line: 54, column: 3, scope: !23, inlinedAt: !24)
!23 = distinct !DISubprogram(name: "__fetch_builtin_y", scope: !16, file: !16, line: 54, type: !12, scopeLine: 54, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!24 = distinct !DILocation(line: 6, column: 39, scope: !11)
!25 = !DILocation(line: 6, column: 37, scope: !11)
!26 = !DILocation(line: 66, column: 3, scope: !27, inlinedAt: !28)
!27 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !16, file: !16, line: 66, type: !12, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!28 = distinct !DILocation(line: 7, column: 13, scope: !11)
!29 = !DILocation(line: 79, column: 3, scope: !30, inlinedAt: !31)
!30 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !16, file: !16, line: 79, type: !12, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!31 = distinct !DILocation(line: 7, column: 26, scope: !11)
!32 = !DILocation(line: 7, column: 24, scope: !11)
!33 = !DILocation(line: 53, column: 3, scope: !34, inlinedAt: !35)
!34 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !16, file: !16, line: 53, type: !12, scopeLine: 53, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!35 = distinct !DILocation(line: 7, column: 39, scope: !11)
!36 = !DILocation(line: 7, column: 37, scope: !11)
!37 = !DILocation(line: 8, column: 11, scope: !11)
!38 = !DILocation(line: 8, column: 15, scope: !11)
!39 = !DILocation(line: 10, column: 23, scope: !11)
!40 = !DILocation(line: 10, column: 5, scope: !11)
!41 = !DILocation(line: 11, column: 24, scope: !11)
!42 = !DILocation(line: 11, column: 14, scope: !11)
!43 = !{!44, !44, i64 0}
!44 = !{!"float", !45, i64 0}
!45 = !{!"omnipotent char", !46, i64 0}
!46 = !{!"Simple C++ TBAA"}
!47 = !DILocation(line: 11, column: 35, scope: !11)
!48 = !DILocation(line: 11, column: 39, scope: !11)
!49 = !DILocation(line: 11, column: 31, scope: !11)
!50 = !DILocation(line: 11, column: 29, scope: !11)
!51 = !DILocation(line: 11, column: 11, scope: !11)
!52 = !DILocation(line: 12, column: 15, scope: !11)
!53 = !DILocation(line: 0, scope: !11)
!54 = !DILocation(line: 12, column: 5, scope: !11)
!55 = !DILocation(line: 12, column: 22, scope: !11)
!56 = !DILocation(line: 13, column: 3, scope: !11)
!57 = !DILocation(line: 10, column: 28, scope: !11)
!58 = distinct !{!58, !40, !59, !60}
!59 = !DILocation(line: 11, column: 44, scope: !11)
!60 = !{!"llvm.loop.mustprogress"}
!61 = !DILocation(line: 14, column: 1, scope: !11)
!62 = distinct !DISubprogram(name: "matmul_swapped", scope: !7, file: !7, line: 18, type: !12, scopeLine: 19, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!63 = !DILocation(line: 66, column: 3, scope: !27, inlinedAt: !64)
!64 = distinct !DILocation(line: 20, column: 13, scope: !62)
!65 = !DILocation(line: 79, column: 3, scope: !30, inlinedAt: !66)
!66 = distinct !DILocation(line: 20, column: 26, scope: !62)
!67 = !DILocation(line: 20, column: 24, scope: !62)
!68 = !DILocation(line: 53, column: 3, scope: !34, inlinedAt: !69)
!69 = distinct !DILocation(line: 20, column: 39, scope: !62)
!70 = !DILocation(line: 20, column: 37, scope: !62)
!71 = !DILocation(line: 67, column: 3, scope: !15, inlinedAt: !72)
!72 = distinct !DILocation(line: 21, column: 13, scope: !62)
!73 = !DILocation(line: 80, column: 3, scope: !19, inlinedAt: !74)
!74 = distinct !DILocation(line: 21, column: 26, scope: !62)
!75 = !DILocation(line: 21, column: 24, scope: !62)
!76 = !DILocation(line: 54, column: 3, scope: !23, inlinedAt: !77)
!77 = distinct !DILocation(line: 21, column: 39, scope: !62)
!78 = !DILocation(line: 21, column: 37, scope: !62)
!79 = !DILocation(line: 22, column: 11, scope: !62)
!80 = !DILocation(line: 22, column: 15, scope: !62)
!81 = !DILocation(line: 24, column: 23, scope: !62)
!82 = !DILocation(line: 24, column: 5, scope: !62)
!83 = !DILocation(line: 25, column: 24, scope: !62)
!84 = !DILocation(line: 25, column: 14, scope: !62)
!85 = !DILocation(line: 25, column: 35, scope: !62)
!86 = !DILocation(line: 25, column: 39, scope: !62)
!87 = !DILocation(line: 25, column: 31, scope: !62)
!88 = !DILocation(line: 25, column: 29, scope: !62)
!89 = !DILocation(line: 25, column: 11, scope: !62)
!90 = !DILocation(line: 26, column: 15, scope: !62)
!91 = !DILocation(line: 0, scope: !62)
!92 = !DILocation(line: 26, column: 5, scope: !62)
!93 = !DILocation(line: 26, column: 22, scope: !62)
!94 = !DILocation(line: 27, column: 3, scope: !62)
!95 = !DILocation(line: 24, column: 28, scope: !62)
!96 = distinct !{!96, !82, !97, !60}
!97 = !DILocation(line: 25, column: 44, scope: !62)
!98 = !DILocation(line: 28, column: 1, scope: !62)
