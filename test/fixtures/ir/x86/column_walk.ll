; ModuleID = 'column_walk.c'
source_filename = "column_walk.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: argmemonly nofree norecurse nosync nounwind uwtable
define dso_local void @scale_columns(ptr noalias nocapture noundef writeonly %out, ptr noalias nocapture noundef readonly %in, i32 noundef %n) local_unnamed_addr #0 !dbg !9 {
entry:
  %cmp24 = icmp sgt i32 %n, 0, !dbg !12
  br i1 %cmp24, label %for.cond1.preheader.lr.ph, label %for.cond.cleanup, !dbg !13

for.cond1.preheader.lr.ph:                        ; preds = %entry
  %0 = zext i32 %n to i64, !dbg !13
  %wide.trip.count32 = zext i32 %n to i64, !dbg !12
  %xtraiter = and i64 %wide.trip.count32, 1
  %1 = icmp eq i32 %n, 1
  %unroll_iter = and i64 %wide.trip.count32, 4294967294
  %lcmp.mod.not = icmp eq i64 %xtraiter, 0
  br label %for.body4.preheader, !dbg !13

for.body4.preheader:                              ; preds = %for.cond.cleanup3, %for.cond1.preheader.lr.ph
  %indvars.iv29 = phi i64 [ 0, %for.cond1.preheader.lr.ph ], [ %indvars.iv.next30, %for.cond.cleanup3 ]
  br i1 %1, label %for.cond.cleanup3.unr-lcssa, label %for.body4, !dbg !14

for.cond.cleanup:                                 ; preds = %for.cond.cleanup3, %entry
  ret void, !dbg !15

for.cond.cleanup3.unr-lcssa:                      ; preds = %for.body4, %for.body4.preheader
  %indvars.iv.unr = phi i64 [ 0, %for.body4.preheader ], [ %indvars.iv.next.1, %for.body4 ]
  br i1 %lcmp.mod.not, label %for.cond.cleanup3, label %for.body4.epil, !dbg !14

for.body4.epil:                                   ; preds = %for.cond.cleanup3.unr-lcssa
  %2 = mul nsw i64 %indvars.iv.unr, %0, !dbg !16
  %3 = add nuw nsw i64 %2, %indvars.iv29, !dbg !17
  %arrayidx.epil = getelementptr inbounds float, ptr %in, i64 %3, !dbg !18
  %4 = load float, ptr %arrayidx.epil, align 4, !dbg !18, !tbaa !19
  %mul5.epil = fmul float %4, 2.000000e+00, !dbg !23
  %arrayidx9.epil = getelementptr inbounds float, ptr %out, i64 %3, !dbg !24
  store float %mul5.epil, ptr %arrayidx9.epil, align 4, !dbg !25, !tbaa !19
  br label %for.cond.cleanup3, !dbg !26

for.cond.cleanup3:                                ; preds = %for.cond.cleanup3.unr-lcssa, %for.body4.epil
  %indvars.iv.next30 = add nuw nsw i64 %indvars.iv29, 1, !dbg !26
  %exitcond33.not = icmp eq i64 %indvars.iv.next30, %wide.trip.count32, !dbg !12
  br i1 %exitcond33.not, label %for.cond.cleanup, label %for.body4.preheader, !dbg !13, !llvm.loop !27

for.body4:                                        ; preds = %for.body4.preheader, %for.body4
  %indvars.iv = phi i64 [ %indvars.iv.next.1, %for.body4 ], [ 0, %for.body4.preheader ]
  %niter = phi i64 [ %niter.next.1, %for.body4 ], [ 0, %for.body4.preheader ]
  %5 = mul nsw i64 %indvars.iv, %0, !dbg !16
  %6 = add nuw nsw i64 %5, %indvars.iv29, !dbg !17
  %arrayidx = getelementptr inbounds float, ptr %in, i64 %6, !dbg !18
  %7 = load float, ptr %arrayidx, align 4, !dbg !18, !tbaa !19
  %mul5 = fmul float %7, 2.000000e+00, !dbg !23
  %arrayidx9 = getelementptr inbounds float, ptr %out, i64 %6, !dbg !24
  store float %mul5, ptr %arrayidx9, align 4, !dbg !25, !tbaa !19
  %indvars.iv.next = or i64 %indvars.iv, 1, !dbg !30
  %8 = mul nsw i64 %indvars.iv.next, %0, !dbg !16
  %9 = add nuw nsw i64 %8, %indvars.iv29, !dbg !17
  %arrayidx.1 = getelementptr inbounds float, ptr %in, i64 %9, !dbg !18
  %10 = load float, ptr %arrayidx.1, align 4, !dbg !18, !tbaa !19
  %mul5.1 = fmul float %10, 2.000000e+00, !dbg !23
  %arrayidx9.1 = getelementptr inbounds float, ptr %out, i64 %9, !dbg !24
  store float %mul5.1, ptr %arrayidx9.1, align 4, !dbg !25, !tbaa !19
  %indvars.iv.next.1 = add nuw nsw i64 %indvars.iv, 2, !dbg !30
  %niter.next.1 = add i64 %niter, 2, !dbg !14
  %niter.ncmp.1 = icmp eq i64 %niter.next.1, %unroll_iter, !dbg !14
  br i1 %niter.ncmp.1, label %for.cond.cleanup3.unr-lcssa, label %for.body4, !dbg !14, !llvm.loop !31
}

attributes #0 = { argmemonly nofree norecurse nosync nounwind uwtable "frame-pointer"="none" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7}
!llvm.ident = !{!8}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "Homebrew clang version 15.0.7", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "column_walk.c", directory: ".", checksumkind: CSK_MD5, checksum: "4faa5a14835d5796dd40baa190bd0e86")
!2 = !{i32 7, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 7, !"PIC Level", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{i32 7, !"uwtable", i32 2}
!8 = !{!"Homebrew clang version 15.0.7"}
!9 = distinct !DISubprogram(name: "scale_columns", scope: !1, file: !1, line: 3, type: !10, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !11)
!10 = !DISubroutineType(types: !11)
!11 = !{}
!12 = !DILocation(line: 4, column: 21, scope: !9)
!13 = !DILocation(line: 4, column: 3, scope: !9)
!14 = !DILocation(line: 5, column: 5, scope: !9)
!15 = !DILocation(line: 7, column: 1, scope: !9)
!16 = !DILocation(line: 6, column: 36, scope: !9)
!17 = !DILocation(line: 6, column: 40, scope: !9)
!18 = !DILocation(line: 6, column: 31, scope: !9)
!19 = !{!20, !20, i64 0}
!20 = !{!"float", !21, i64 0}
!21 = !{!"omnipotent char", !22, i64 0}
!22 = !{!"Simple C/C++ TBAA"}
!23 = !DILocation(line: 6, column: 29, scope: !9)
!24 = !DILocation(line: 6, column: 7, scope: !9)
!25 = !DILocation(line: 6, column: 22, scope: !9)
!26 = !DILocation(line: 4, column: 26, scope: !9)
!27 = distinct !{!27, !13, !28, !29}
!28 = !DILocation(line: 6, column: 43, scope: !9)
!29 = !{!"llvm.loop.mustprogress"}
!30 = !DILocation(line: 5, column: 28, scope: !9)
!31 = distinct !{!31, !14, !28, !29}
