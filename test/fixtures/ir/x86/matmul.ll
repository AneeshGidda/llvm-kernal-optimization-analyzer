; ModuleID = 'matmul.c'
source_filename = "matmul.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: argmemonly nofree nosync nounwind uwtable
define dso_local void @matmul(ptr nocapture noundef readonly %A, ptr nocapture noundef readonly %B, ptr nocapture noundef writeonly %C, i32 noundef %n) local_unnamed_addr #0 !dbg !9 {
entry:
  %cmp44 = icmp sgt i32 %n, 0, !dbg !12
  br i1 %cmp44, label %for.cond1.preheader.lr.ph, label %for.cond.cleanup, !dbg !13

for.cond1.preheader.lr.ph:                        ; preds = %entry
  %0 = zext i32 %n to i64, !dbg !13
  %wide.trip.count61 = zext i32 %n to i64, !dbg !12
  %xtraiter = and i64 %wide.trip.count61, 1
  %1 = icmp eq i32 %n, 1
  %unroll_iter = and i64 %wide.trip.count61, 4294967294
  %lcmp.mod.not = icmp eq i64 %xtraiter, 0
  br label %for.cond5.preheader.lr.ph, !dbg !13

for.cond5.preheader.lr.ph:                        ; preds = %for.cond.cleanup3, %for.cond1.preheader.lr.ph
  %indvars.iv56 = phi i64 [ 0, %for.cond1.preheader.lr.ph ], [ %indvars.iv.next57, %for.cond.cleanup3 ]
  %2 = mul nsw i64 %indvars.iv56, %0
  br label %for.body8.preheader, !dbg !14

for.cond.cleanup:                                 ; preds = %for.cond.cleanup3, %entry
  ret void, !dbg !15

for.body8.preheader:                              ; preds = %for.cond.cleanup7, %for.cond5.preheader.lr.ph
  %indvars.iv50 = phi i64 [ 0, %for.cond5.preheader.lr.ph ], [ %indvars.iv.next51, %for.cond.cleanup7 ]
  br i1 %1, label %for.cond.cleanup7.unr-lcssa, label %for.body8, !dbg !16

for.cond.cleanup3:                                ; preds = %for.cond.cleanup7
  %indvars.iv.next57 = add nuw nsw i64 %indvars.iv56, 1, !dbg !17
  %exitcond62.not = icmp eq i64 %indvars.iv.next57, %wide.trip.count61, !dbg !12
  br i1 %exitcond62.not, label %for.cond.cleanup, label %for.cond5.preheader.lr.ph, !dbg !13, !llvm.loop !18

for.cond.cleanup7.unr-lcssa:                      ; preds = %for.body8, %for.body8.preheader
  %.lcssa.ph = phi float [ undef, %for.body8.preheader ], [ %21, %for.body8 ]
  %indvars.iv.unr = phi i64 [ 0, %for.body8.preheader ], [ %indvars.iv.next.1, %for.body8 ]
  %sum.040.unr = phi float [ 0.000000e+00, %for.body8.preheader ], [ %21, %for.body8 ]
  br i1 %lcmp.mod.not, label %for.cond.cleanup7, label %for.body8.epil, !dbg !16

for.body8.epil:                                   ; preds = %for.cond.cleanup7.unr-lcssa
  %3 = add nuw nsw i64 %indvars.iv.unr, %2, !dbg !21
  %arrayidx.epil = getelementptr inbounds float, ptr %A, i64 %3, !dbg !22
  %4 = load float, ptr %arrayidx.epil, align 4, !dbg !22, !tbaa !23
  %5 = mul nsw i64 %indvars.iv.unr, %0, !dbg !27
  %6 = add nuw nsw i64 %5, %indvars.iv50, !dbg !28
  %arrayidx12.epil = getelementptr inbounds float, ptr %B, i64 %6, !dbg !29
  %7 = load float, ptr %arrayidx12.epil, align 4, !dbg !29, !tbaa !23
  %8 = tail call float @llvm.fmuladd.f32(float %4, float %7, float %sum.040.unr), !dbg !30
  br label %for.cond.cleanup7, !dbg !31

for.cond.cleanup7:                                ; preds = %for.cond.cleanup7.unr-lcssa, %for.body8.epil
  %.lcssa = phi float [ %.lcssa.ph, %for.cond.cleanup7.unr-lcssa ], [ %8, %for.body8.epil ], !dbg !30
  %9 = add nuw nsw i64 %indvars.iv50, %2, !dbg !31
  %arrayidx17 = getelementptr inbounds float, ptr %C, i64 %9, !dbg !32
  store float %.lcssa, ptr %arrayidx17, align 4, !dbg !33, !tbaa !23
  %indvars.iv.next51 = add nuw nsw i64 %indvars.iv50, 1, !dbg !34
  %exitcond55.not = icmp eq i64 %indvars.iv.next51, %wide.trip.count61, !dbg !35
  br i1 %exitcond55.not, label %for.cond.cleanup3, label %for.body8.preheader, !dbg !14, !llvm.loop !36

for.body8:                                        ; preds = %for.body8.preheader, %for.body8
  %indvars.iv = phi i64 [ %indvars.iv.next.1, %for.body8 ], [ 0, %for.body8.preheader ]
  %sum.040 = phi float [ %21, %for.body8 ], [ 0.000000e+00, %for.body8.preheader ]
  %niter = phi i64 [ %niter.next.1, %for.body8 ], [ 0, %for.body8.preheader ]
  %10 = add nuw nsw i64 %indvars.iv, %2, !dbg !21
  %arrayidx = getelementptr inbounds float, ptr %A, i64 %10, !dbg !22
  %11 = load float, ptr %arrayidx, align 4, !dbg !22, !tbaa !23
  %12 = mul nsw i64 %indvars.iv, %0, !dbg !27
  %13 = add nuw nsw i64 %12, %indvars.iv50, !dbg !28
  %arrayidx12 = getelementptr inbounds float, ptr %B, i64 %13, !dbg !29
  %14 = load float, ptr %arrayidx12, align 4, !dbg !29, !tbaa !23
  %15 = tail call float @llvm.fmuladd.f32(float %11, float %14, float %sum.040), !dbg !30
  %indvars.iv.next = or i64 %indvars.iv, 1, !dbg !37
  %16 = add nuw nsw i64 %indvars.iv.next, %2, !dbg !21
  %arrayidx.1 = getelementptr inbounds float, ptr %A, i64 %16, !dbg !22
  %17 = load float, ptr %arrayidx.1, align 4, !dbg !22, !tbaa !23
  %18 = mul nsw i64 %indvars.iv.next, %0, !dbg !27
  %19 = add nuw nsw i64 %18, %indvars.iv50, !dbg !28
  %arrayidx12.1 = getelementptr inbounds float, ptr %B, i64 %19, !dbg !29
  %20 = load float, ptr %arrayidx12.1, align 4, !dbg !29, !tbaa !23
  %21 = tail call float @llvm.fmuladd.f32(float %17, float %20, float %15), !dbg !30
  %indvars.iv.next.1 = add nuw nsw i64 %indvars.iv, 2, !dbg !37
  %niter.next.1 = add i64 %niter, 2, !dbg !16
  %niter.ncmp.1 = icmp eq i64 %niter.next.1, %unroll_iter, !dbg !16
  br i1 %niter.ncmp.1, label %for.cond.cleanup7.unr-lcssa, label %for.body8, !dbg !16, !llvm.loop !38
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare float @llvm.fmuladd.f32(float, float, float) #1

attributes #0 = { argmemonly nofree nosync nounwind uwtable "frame-pointer"="none" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7}
!llvm.ident = !{!8}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "Homebrew clang version 15.0.7", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "matmul.c", directory: ".", checksumkind: CSK_MD5, checksum: "31d35f2a3380362a38504dedbfb32dcf")
!2 = !{i32 7, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 7, !"PIC Level", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{i32 7, !"uwtable", i32 2}
!8 = !{!"Homebrew clang version 15.0.7"}
!9 = distinct !DISubprogram(name: "matmul", scope: !1, file: !1, line: 4, type: !10, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !11)
!10 = !DISubroutineType(types: !11)
!11 = !{}
!12 = !DILocation(line: 5, column: 21, scope: !9)
!13 = !DILocation(line: 5, column: 3, scope: !9)
!14 = !DILocation(line: 6, column: 5, scope: !9)
!15 = !DILocation(line: 12, column: 1, scope: !9)
!16 = !DILocation(line: 8, column: 7, scope: !9)
!17 = !DILocation(line: 5, column: 26, scope: !9)
!18 = distinct !{!18, !13, !19, !20}
!19 = !DILocation(line: 11, column: 5, scope: !9)
!20 = !{!"llvm.loop.mustprogress"}
!21 = !DILocation(line: 9, column: 24, scope: !9)
!22 = !DILocation(line: 9, column: 16, scope: !9)
!23 = !{!24, !24, i64 0}
!24 = !{!"float", !25, i64 0}
!25 = !{!"omnipotent char", !26, i64 0}
!26 = !{!"Simple C/C++ TBAA"}
!27 = !DILocation(line: 9, column: 35, scope: !9)
!28 = !DILocation(line: 9, column: 39, scope: !9)
!29 = !DILocation(line: 9, column: 31, scope: !9)
!30 = !DILocation(line: 9, column: 13, scope: !9)
!31 = !DILocation(line: 10, column: 15, scope: !9)
!32 = !DILocation(line: 10, column: 7, scope: !9)
!33 = !DILocation(line: 10, column: 20, scope: !9)
!34 = !DILocation(line: 6, column: 28, scope: !9)
!35 = !DILocation(line: 6, column: 23, scope: !9)
!36 = distinct !{!36, !14, !19, !20}
!37 = !DILocation(line: 8, column: 30, scope: !9)
!38 = distinct !{!38, !16, !39, !20}
!39 = !DILocation(line: 9, column: 42, scope: !9)
