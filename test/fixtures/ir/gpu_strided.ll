; ModuleID = 'gpu_strided.cu'
source_filename = "gpu_strided.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.Particle = type { float, float, float }

; Function Attrs: argmemonly mustprogress nofree norecurse nosync nounwind willreturn
define dso_local void @_Z7shift_xP8Particlefi(ptr nocapture noundef %p, float noundef %dx, i32 noundef %n) local_unnamed_addr #0 !dbg !12 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !15
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !19
  %mul = mul i32 %0, %1, !dbg !22
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !23
  %add = add i32 %mul, %2, !dbg !26
  %cmp = icmp slt i32 %add, %n, !dbg !27
  br i1 %cmp, label %if.then, label %if.end, !dbg !28

if.then:                                          ; preds = %entry
  %idxprom = sext i32 %add to i64, !dbg !29
  %arrayidx = getelementptr inbounds %struct.Particle, ptr %p, i64 %idxprom, !dbg !29
  %3 = load float, ptr %arrayidx, align 4, !dbg !30, !tbaa !31
  %add3 = fadd contract float %3, %dx, !dbg !30
  store float %add3, ptr %arrayidx, align 4, !dbg !30, !tbaa !31
  br label %if.end, !dbg !29

if.end:                                           ; preds = %if.then, %entry
  ret void, !dbg !36
}

; Function Attrs: argmemonly mustprogress nofree norecurse nosync nounwind
define dso_local void @_Z8row_sumsPKfPfi(ptr nocapture noundef readonly %m, ptr nocapture noundef writeonly %out, i32 noundef %n) local_unnamed_addr #1 !dbg !37 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !38
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !40
  %mul = mul i32 %0, %1, !dbg !42
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !43
  %add = add i32 %mul, %2, !dbg !45
  %cmp.not = icmp slt i32 %add, %n, !dbg !46
  br i1 %cmp.not, label %for.cond.preheader, label %cleanup, !dbg !47

for.cond.preheader:                               ; preds = %entry
  %cmp316 = icmp sgt i32 %n, 0, !dbg !48
  br i1 %cmp316, label %for.body.lr.ph, label %for.cond.cleanup, !dbg !49

for.body.lr.ph:                                   ; preds = %for.cond.preheader
  %mul4 = mul nsw i32 %add, %n
  %3 = add i32 %n, -1, !dbg !49
  %xtraiter = and i32 %n, 3, !dbg !49
  %4 = icmp ult i32 %3, 3, !dbg !49
  br i1 %4, label %for.cond.cleanup.loopexit.unr-lcssa, label %for.body.lr.ph.new, !dbg !49

for.body.lr.ph.new:                               ; preds = %for.body.lr.ph
  %unroll_iter = and i32 %n, -4, !dbg !49
  br label %for.body, !dbg !49

for.cond.cleanup.loopexit.unr-lcssa:              ; preds = %for.body, %for.body.lr.ph
  %add6.lcssa.ph = phi float [ undef, %for.body.lr.ph ], [ %add6.3, %for.body ]
  %j.018.unr = phi i32 [ 0, %for.body.lr.ph ], [ %inc.3, %for.body ]
  %s.017.unr = phi float [ 0.000000e+00, %for.body.lr.ph ], [ %add6.3, %for.body ]
  %lcmp.mod.not = icmp eq i32 %xtraiter, 0, !dbg !49
  br i1 %lcmp.mod.not, label %for.cond.cleanup, label %for.body.epil, !dbg !49

for.body.epil:                                    ; preds = %for.cond.cleanup.loopexit.unr-lcssa, %for.body.epil
  %j.018.epil = phi i32 [ %inc.epil, %for.body.epil ], [ %j.018.unr, %for.cond.cleanup.loopexit.unr-lcssa ]
  %s.017.epil = phi float [ %add6.epil, %for.body.epil ], [ %s.017.unr, %for.cond.cleanup.loopexit.unr-lcssa ]
  %epil.iter = phi i32 [ %epil.iter.next, %for.body.epil ], [ 0, %for.cond.cleanup.loopexit.unr-lcssa ]
  %add5.epil = add nsw i32 %j.018.epil, %mul4, !dbg !50
  %idxprom.epil = sext i32 %add5.epil to i64, !dbg !51
  %arrayidx.epil = getelementptr inbounds float, ptr %m, i64 %idxprom.epil, !dbg !51
  %5 = load float, ptr %arrayidx.epil, align 4, !dbg !51, !tbaa !52
  %add6.epil = fadd contract float %s.017.epil, %5, !dbg !53
  %inc.epil = add nuw nsw i32 %j.018.epil, 1, !dbg !54
  %epil.iter.next = add i32 %epil.iter, 1, !dbg !49
  %epil.iter.cmp.not = icmp eq i32 %epil.iter.next, %xtraiter, !dbg !49
  br i1 %epil.iter.cmp.not, label %for.cond.cleanup, label %for.body.epil, !dbg !49, !llvm.loop !55

for.cond.cleanup:                                 ; preds = %for.cond.cleanup.loopexit.unr-lcssa, %for.body.epil, %for.cond.preheader
  %s.0.lcssa = phi float [ 0.000000e+00, %for.cond.preheader ], [ %add6.lcssa.ph, %for.cond.cleanup.loopexit.unr-lcssa ], [ %add6.epil, %for.body.epil ], !dbg !57
  %idxprom7 = sext i32 %add to i64, !dbg !58
  %arrayidx8 = getelementptr inbounds float, ptr %out, i64 %idxprom7, !dbg !58
  store float %s.0.lcssa, ptr %arrayidx8, align 4, !dbg !59, !tbaa !52
  br label %cleanup, !dbg !60

for.body:                                         ; preds = %for.body, %for.body.lr.ph.new
  %j.018 = phi i32 [ 0, %for.body.lr.ph.new ], [ %inc.3, %for.body ]
  %s.017 = phi float [ 0.000000e+00, %for.body.lr.ph.new ], [ %add6.3, %for.body ]
  %niter = phi i32 [ 0, %for.body.lr.ph.new ], [ %niter.next.3, %for.body ]
  %add5 = add nsw i32 %j.018, %mul4, !dbg !50
  %idxprom = sext i32 %add5 to i64, !dbg !51
  %arrayidx = getelementptr inbounds float, ptr %m, i64 %idxprom, !dbg !51
  %6 = load float, ptr %arrayidx, align 4, !dbg !51, !tbaa !52
  %add6 = fadd contract float %s.017, %6, !dbg !53
  %inc = or i32 %j.018, 1, !dbg !54
  %add5.1 = add nsw i32 %inc, %mul4, !dbg !50
  %idxprom.1 = sext i32 %add5.1 to i64, !dbg !51
  %arrayidx.1 = getelementptr inbounds float, ptr %m, i64 %idxprom.1, !dbg !51
  %7 = load float, ptr %arrayidx.1, align 4, !dbg !51, !tbaa !52
  %add6.1 = fadd contract float %add6, %7, !dbg !53
  %inc.1 = or i32 %j.018, 2, !dbg !54
  %add5.2 = add nsw i32 %inc.1, %mul4, !dbg !50
  %idxprom.2 = sext i32 %add5.2 to i64, !dbg !51
  %arrayidx.2 = getelementptr inbounds float, ptr %m, i64 %idxprom.2, !dbg !51
  %8 = load float, ptr %arrayidx.2, align 4, !dbg !51, !tbaa !52
  %add6.2 = fadd contract float %add6.1, %8, !dbg !53
  %inc.2 = or i32 %j.018, 3, !dbg !54
  %add5.3 = add nsw i32 %inc.2, %mul4, !dbg !50
  %idxprom.3 = sext i32 %add5.3 to i64, !dbg !51
  %arrayidx.3 = getelementptr inbounds float, ptr %m, i64 %idxprom.3, !dbg !51
  %9 = load float, ptr %arrayidx.3, align 4, !dbg !51, !tbaa !52
  %add6.3 = fadd contract float %add6.2, %9, !dbg !53
  %inc.3 = add nuw nsw i32 %j.018, 4, !dbg !54
  %niter.next.3 = add i32 %niter, 4, !dbg !49
  %niter.ncmp.3 = icmp eq i32 %niter.next.3, %unroll_iter, !dbg !49
  br i1 %niter.ncmp.3, label %for.cond.cleanup.loopexit.unr-lcssa, label %for.body, !dbg !49, !llvm.loop !61

cleanup:                                          ; preds = %entry, %for.cond.cleanup
  ret void, !dbg !60
}

; Function Attrs: argmemonly mustprogress nofree norecurse nosync nounwind willreturn
define dso_local void @_Z9take_evenPKfPfi(ptr nocapture noundef readonly %in, ptr nocapture noundef writeonly %out, i32 noundef %n) local_unnamed_addr #0 !dbg !64 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !65
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !67
  %mul = mul i32 %0, %1, !dbg !69
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !70
  %add = add i32 %mul, %2, !dbg !72
  %cmp = icmp slt i32 %add, %n, !dbg !73
  br i1 %cmp, label %if.then, label %if.end, !dbg !74

if.then:                                          ; preds = %entry
  %idxprom4 = sext i32 %add to i64, !dbg !75
  %arrayidx5 = getelementptr inbounds float, ptr %out, i64 %idxprom4, !dbg !75
  %mul3 = shl nsw i32 %add, 1, !dbg !76
  %idxprom = sext i32 %mul3 to i64, !dbg !77
  %arrayidx = getelementptr inbounds float, ptr %in, i64 %idxprom, !dbg !77
  %3 = load float, ptr %arrayidx, align 4, !dbg !77, !tbaa !52
  store float %3, ptr %arrayidx5, align 4, !dbg !78, !tbaa !52
  br label %if.end, !dbg !75

if.end:                                           ; preds = %if.then, %entry
  ret void, !dbg !79
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.tid.x() #2

attributes #0 = { argmemonly mustprogress nofree norecurse nosync nounwind willreturn "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_70" "target-features"="+ptx42,+sm_70" }
attributes #1 = { argmemonly mustprogress nofree norecurse nosync nounwind "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_70" "target-features"="+ptx42,+sm_70" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5}
!llvm.dbg.cu = !{!6}
!nvvm.annotations = !{!8, !9, !10}
!llvm.ident = !{!11}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 2]}
!1 = !{i32 7, !"Dwarf Version", i32 2}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !7, producer: "Homebrew clang version 15.0.7", isOptimized: true, runtimeVersion: 0, emissionKind: DebugDirectivesOnly, splitDebugInlining: false, nameTableKind: None)
!7 = !DIFile(filename: "gpu_strided.cu", directory: ".")
!8 = !{ptr @_Z7shift_xP8Particlefi, !"kernel", i32 1}
!9 = !{ptr @_Z8row_sumsPKfPfi, !"kernel", i32 1}
!10 = !{ptr @_Z9take_evenPKfPfi, !"kernel", i32 1}
!11 = !{!"Homebrew clang version 15.0.7"}
!12 = distinct !DISubprogram(name: "shift_x", scope: !7, file: !7, line: 8, type: !13, scopeLine: 8, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !14)
!13 = !DISubroutineType(types: !14)
!14 = !{}
!15 = !DILocation(line: 66, column: 3, scope: !16, inlinedAt: !18)
!16 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !17, file: !17, line: 66, type: !13, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !14)
!17 = !DIFile(filename: "/opt/homebrew/Cellar/llvm@15/15.0.7/lib/clang/15.0.7/include/__clang_cuda_builtin_vars.h", directory: "")
!18 = distinct !DILocation(line: 9, column: 11, scope: !12)
!19 = !DILocation(line: 79, column: 3, scope: !20, inlinedAt: !21)
!20 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !17, file: !17, line: 79, type: !13, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !14)
!21 = distinct !DILocation(line: 9, column: 24, scope: !12)
!22 = !DILocation(line: 9, column: 22, scope: !12)
!23 = !DILocation(line: 53, column: 3, scope: !24, inlinedAt: !25)
!24 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !17, file: !17, line: 53, type: !13, scopeLine: 53, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !14)
!25 = distinct !DILocation(line: 9, column: 37, scope: !12)
!26 = !DILocation(line: 9, column: 35, scope: !12)
!27 = !DILocation(line: 10, column: 9, scope: !12)
!28 = !DILocation(line: 10, column: 7, scope: !12)
!29 = !DILocation(line: 11, column: 5, scope: !12)
!30 = !DILocation(line: 11, column: 12, scope: !12)
!31 = !{!32, !33, i64 0}
!32 = !{!"_ZTS8Particle", !33, i64 0, !33, i64 4, !33, i64 8}
!33 = !{!"float", !34, i64 0}
!34 = !{!"omnipotent char", !35, i64 0}
!35 = !{!"Simple C++ TBAA"}
!36 = !DILocation(line: 12, column: 1, scope: !12)
!37 = distinct !DISubprogram(name: "row_sums", scope: !7, file: !7, line: 16, type: !13, scopeLine: 16, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !14)
!38 = !DILocation(line: 66, column: 3, scope: !16, inlinedAt: !39)
!39 = distinct !DILocation(line: 17, column: 13, scope: !37)
!40 = !DILocation(line: 79, column: 3, scope: !20, inlinedAt: !41)
!41 = distinct !DILocation(line: 17, column: 26, scope: !37)
!42 = !DILocation(line: 17, column: 24, scope: !37)
!43 = !DILocation(line: 53, column: 3, scope: !24, inlinedAt: !44)
!44 = distinct !DILocation(line: 17, column: 39, scope: !37)
!45 = !DILocation(line: 17, column: 37, scope: !37)
!46 = !DILocation(line: 18, column: 11, scope: !37)
!47 = !DILocation(line: 18, column: 7, scope: !37)
!48 = !DILocation(line: 21, column: 21, scope: !37)
!49 = !DILocation(line: 21, column: 3, scope: !37)
!50 = !DILocation(line: 22, column: 20, scope: !37)
!51 = !DILocation(line: 22, column: 10, scope: !37)
!52 = !{!33, !33, i64 0}
!53 = !DILocation(line: 22, column: 7, scope: !37)
!54 = !DILocation(line: 21, column: 26, scope: !37)
!55 = distinct !{!55, !56}
!56 = !{!"llvm.loop.unroll.disable"}
!57 = !DILocation(line: 0, scope: !37)
!58 = !DILocation(line: 23, column: 3, scope: !37)
!59 = !DILocation(line: 23, column: 12, scope: !37)
!60 = !DILocation(line: 24, column: 1, scope: !37)
!61 = distinct !{!61, !49, !62, !63}
!62 = !DILocation(line: 22, column: 23, scope: !37)
!63 = !{!"llvm.loop.mustprogress"}
!64 = distinct !DISubprogram(name: "take_even", scope: !7, file: !7, line: 27, type: !13, scopeLine: 27, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !14)
!65 = !DILocation(line: 66, column: 3, scope: !16, inlinedAt: !66)
!66 = distinct !DILocation(line: 28, column: 11, scope: !64)
!67 = !DILocation(line: 79, column: 3, scope: !20, inlinedAt: !68)
!68 = distinct !DILocation(line: 28, column: 24, scope: !64)
!69 = !DILocation(line: 28, column: 22, scope: !64)
!70 = !DILocation(line: 53, column: 3, scope: !24, inlinedAt: !71)
!71 = distinct !DILocation(line: 28, column: 37, scope: !64)
!72 = !DILocation(line: 28, column: 35, scope: !64)
!73 = !DILocation(line: 29, column: 9, scope: !64)
!74 = !DILocation(line: 29, column: 7, scope: !64)
!75 = !DILocation(line: 30, column: 5, scope: !64)
!76 = !DILocation(line: 30, column: 19, scope: !64)
!77 = !DILocation(line: 30, column: 14, scope: !64)
!78 = !DILocation(line: 30, column: 12, scope: !64)
!79 = !DILocation(line: 31, column: 1, scope: !64)
