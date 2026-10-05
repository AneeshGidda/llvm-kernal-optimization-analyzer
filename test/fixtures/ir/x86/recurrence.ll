; ModuleID = 'recurrence.c'
source_filename = "recurrence.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: argmemonly nofree norecurse nosync nounwind uwtable
define dso_local void @prefix_sum(ptr nocapture noundef %a, ptr nocapture noundef readonly %b, i32 noundef %n) local_unnamed_addr #0 !dbg !9 {
entry:
  %cmp10 = icmp sgt i32 %n, 1, !dbg !12
  br i1 %cmp10, label %for.body.preheader, label %for.cond.cleanup, !dbg !13

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !12
  %.pre = load float, ptr %a, align 4, !dbg !14, !tbaa !15
  %0 = add nsw i64 %wide.trip.count, -1, !dbg !13
  %1 = add nsw i64 %wide.trip.count, -2, !dbg !13
  %xtraiter = and i64 %0, 3, !dbg !13
  %2 = icmp ult i64 %1, 3, !dbg !13
  br i1 %2, label %for.cond.cleanup.loopexit.unr-lcssa, label %for.body.preheader.new, !dbg !13

for.body.preheader.new:                           ; preds = %for.body.preheader
  %unroll_iter = and i64 %0, -4, !dbg !13
  br label %for.body, !dbg !13

for.cond.cleanup.loopexit.unr-lcssa:              ; preds = %for.body, %for.body.preheader
  %.unr = phi float [ %.pre, %for.body.preheader ], [ %add.3, %for.body ]
  %indvars.iv.unr = phi i64 [ 1, %for.body.preheader ], [ %indvars.iv.next.3, %for.body ]
  %lcmp.mod.not = icmp eq i64 %xtraiter, 0, !dbg !13
  br i1 %lcmp.mod.not, label %for.cond.cleanup, label %for.body.epil, !dbg !13

for.body.epil:                                    ; preds = %for.cond.cleanup.loopexit.unr-lcssa, %for.body.epil
  %3 = phi float [ %add.epil, %for.body.epil ], [ %.unr, %for.cond.cleanup.loopexit.unr-lcssa ], !dbg !14
  %indvars.iv.epil = phi i64 [ %indvars.iv.next.epil, %for.body.epil ], [ %indvars.iv.unr, %for.cond.cleanup.loopexit.unr-lcssa ]
  %epil.iter = phi i64 [ %epil.iter.next, %for.body.epil ], [ 0, %for.cond.cleanup.loopexit.unr-lcssa ]
  %arrayidx2.epil = getelementptr inbounds float, ptr %b, i64 %indvars.iv.epil, !dbg !19
  %4 = load float, ptr %arrayidx2.epil, align 4, !dbg !19, !tbaa !15
  %add.epil = fadd float %3, %4, !dbg !20
  %arrayidx4.epil = getelementptr inbounds float, ptr %a, i64 %indvars.iv.epil, !dbg !21
  store float %add.epil, ptr %arrayidx4.epil, align 4, !dbg !22, !tbaa !15
  %indvars.iv.next.epil = add nuw nsw i64 %indvars.iv.epil, 1, !dbg !23
  %epil.iter.next = add i64 %epil.iter, 1, !dbg !13
  %epil.iter.cmp.not = icmp eq i64 %epil.iter.next, %xtraiter, !dbg !13
  br i1 %epil.iter.cmp.not, label %for.cond.cleanup, label %for.body.epil, !dbg !13, !llvm.loop !24

for.cond.cleanup:                                 ; preds = %for.cond.cleanup.loopexit.unr-lcssa, %for.body.epil, %entry
  ret void, !dbg !26

for.body:                                         ; preds = %for.body, %for.body.preheader.new
  %5 = phi float [ %.pre, %for.body.preheader.new ], [ %add.3, %for.body ], !dbg !14
  %indvars.iv = phi i64 [ 1, %for.body.preheader.new ], [ %indvars.iv.next.3, %for.body ]
  %niter = phi i64 [ 0, %for.body.preheader.new ], [ %niter.next.3, %for.body ]
  %arrayidx2 = getelementptr inbounds float, ptr %b, i64 %indvars.iv, !dbg !19
  %6 = load float, ptr %arrayidx2, align 4, !dbg !19, !tbaa !15
  %add = fadd float %5, %6, !dbg !20
  %arrayidx4 = getelementptr inbounds float, ptr %a, i64 %indvars.iv, !dbg !21
  store float %add, ptr %arrayidx4, align 4, !dbg !22, !tbaa !15
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !23
  %arrayidx2.1 = getelementptr inbounds float, ptr %b, i64 %indvars.iv.next, !dbg !19
  %7 = load float, ptr %arrayidx2.1, align 4, !dbg !19, !tbaa !15
  %add.1 = fadd float %add, %7, !dbg !20
  %arrayidx4.1 = getelementptr inbounds float, ptr %a, i64 %indvars.iv.next, !dbg !21
  store float %add.1, ptr %arrayidx4.1, align 4, !dbg !22, !tbaa !15
  %indvars.iv.next.1 = add nuw nsw i64 %indvars.iv, 2, !dbg !23
  %arrayidx2.2 = getelementptr inbounds float, ptr %b, i64 %indvars.iv.next.1, !dbg !19
  %8 = load float, ptr %arrayidx2.2, align 4, !dbg !19, !tbaa !15
  %add.2 = fadd float %add.1, %8, !dbg !20
  %arrayidx4.2 = getelementptr inbounds float, ptr %a, i64 %indvars.iv.next.1, !dbg !21
  store float %add.2, ptr %arrayidx4.2, align 4, !dbg !22, !tbaa !15
  %indvars.iv.next.2 = add nuw nsw i64 %indvars.iv, 3, !dbg !23
  %arrayidx2.3 = getelementptr inbounds float, ptr %b, i64 %indvars.iv.next.2, !dbg !19
  %9 = load float, ptr %arrayidx2.3, align 4, !dbg !19, !tbaa !15
  %add.3 = fadd float %add.2, %9, !dbg !20
  %arrayidx4.3 = getelementptr inbounds float, ptr %a, i64 %indvars.iv.next.2, !dbg !21
  store float %add.3, ptr %arrayidx4.3, align 4, !dbg !22, !tbaa !15
  %indvars.iv.next.3 = add nuw nsw i64 %indvars.iv, 4, !dbg !23
  %niter.next.3 = add i64 %niter, 4, !dbg !13
  %niter.ncmp.3 = icmp eq i64 %niter.next.3, %unroll_iter, !dbg !13
  br i1 %niter.ncmp.3, label %for.cond.cleanup.loopexit.unr-lcssa, label %for.body, !dbg !13, !llvm.loop !27
}

attributes #0 = { argmemonly nofree norecurse nosync nounwind uwtable "frame-pointer"="none" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7}
!llvm.ident = !{!8}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "Homebrew clang version 15.0.7", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "recurrence.c", directory: ".", checksumkind: CSK_MD5, checksum: "ce97fa2a4305dc59f8794c9b39b9bc2b")
!2 = !{i32 7, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 7, !"PIC Level", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{i32 7, !"uwtable", i32 2}
!8 = !{!"Homebrew clang version 15.0.7"}
!9 = distinct !DISubprogram(name: "prefix_sum", scope: !1, file: !1, line: 2, type: !10, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !11)
!10 = !DISubroutineType(types: !11)
!11 = !{}
!12 = !DILocation(line: 3, column: 21, scope: !9)
!13 = !DILocation(line: 3, column: 3, scope: !9)
!14 = !DILocation(line: 4, column: 12, scope: !9)
!15 = !{!16, !16, i64 0}
!16 = !{!"float", !17, i64 0}
!17 = !{!"omnipotent char", !18, i64 0}
!18 = !{!"Simple C/C++ TBAA"}
!19 = !DILocation(line: 4, column: 23, scope: !9)
!20 = !DILocation(line: 4, column: 21, scope: !9)
!21 = !DILocation(line: 4, column: 5, scope: !9)
!22 = !DILocation(line: 4, column: 10, scope: !9)
!23 = !DILocation(line: 3, column: 26, scope: !9)
!24 = distinct !{!24, !25}
!25 = !{!"llvm.loop.unroll.disable"}
!26 = !DILocation(line: 5, column: 1, scope: !9)
!27 = distinct !{!27, !13, !28, !29}
!28 = !DILocation(line: 4, column: 26, scope: !9)
!29 = !{!"llvm.loop.mustprogress"}
