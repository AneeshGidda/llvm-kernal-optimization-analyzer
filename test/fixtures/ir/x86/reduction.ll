; ModuleID = 'reduction.c'
source_filename = "reduction.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: argmemonly nofree norecurse nosync nounwind readonly uwtable
define dso_local float @sum_f32(ptr nocapture noundef readonly %a, i32 noundef %n) local_unnamed_addr #0 !dbg !9 {
entry:
  %cmp4 = icmp sgt i32 %n, 0, !dbg !12
  br i1 %cmp4, label %for.body.preheader, label %for.cond.cleanup, !dbg !13

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !12
  %0 = add nsw i64 %wide.trip.count, -1, !dbg !13
  %xtraiter = and i64 %wide.trip.count, 7, !dbg !13
  %1 = icmp ult i64 %0, 7, !dbg !13
  br i1 %1, label %for.cond.cleanup.loopexit.unr-lcssa, label %for.body.preheader.new, !dbg !13

for.body.preheader.new:                           ; preds = %for.body.preheader
  %unroll_iter = and i64 %wide.trip.count, 4294967288, !dbg !13
  br label %for.body, !dbg !13

for.cond.cleanup.loopexit.unr-lcssa:              ; preds = %for.body, %for.body.preheader
  %add.lcssa.ph = phi float [ undef, %for.body.preheader ], [ %add.7, %for.body ]
  %indvars.iv.unr = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next.7, %for.body ]
  %s.05.unr = phi float [ 0.000000e+00, %for.body.preheader ], [ %add.7, %for.body ]
  %lcmp.mod.not = icmp eq i64 %xtraiter, 0, !dbg !13
  br i1 %lcmp.mod.not, label %for.cond.cleanup, label %for.body.epil, !dbg !13

for.body.epil:                                    ; preds = %for.cond.cleanup.loopexit.unr-lcssa, %for.body.epil
  %indvars.iv.epil = phi i64 [ %indvars.iv.next.epil, %for.body.epil ], [ %indvars.iv.unr, %for.cond.cleanup.loopexit.unr-lcssa ]
  %s.05.epil = phi float [ %add.epil, %for.body.epil ], [ %s.05.unr, %for.cond.cleanup.loopexit.unr-lcssa ]
  %epil.iter = phi i64 [ %epil.iter.next, %for.body.epil ], [ 0, %for.cond.cleanup.loopexit.unr-lcssa ]
  %arrayidx.epil = getelementptr inbounds float, ptr %a, i64 %indvars.iv.epil, !dbg !14
  %2 = load float, ptr %arrayidx.epil, align 4, !dbg !14, !tbaa !15
  %add.epil = fadd float %s.05.epil, %2, !dbg !19
  %indvars.iv.next.epil = add nuw nsw i64 %indvars.iv.epil, 1, !dbg !20
  %epil.iter.next = add i64 %epil.iter, 1, !dbg !13
  %epil.iter.cmp.not = icmp eq i64 %epil.iter.next, %xtraiter, !dbg !13
  br i1 %epil.iter.cmp.not, label %for.cond.cleanup, label %for.body.epil, !dbg !13, !llvm.loop !21

for.cond.cleanup:                                 ; preds = %for.cond.cleanup.loopexit.unr-lcssa, %for.body.epil, %entry
  %s.0.lcssa = phi float [ 0.000000e+00, %entry ], [ %add.lcssa.ph, %for.cond.cleanup.loopexit.unr-lcssa ], [ %add.epil, %for.body.epil ], !dbg !23
  ret float %s.0.lcssa, !dbg !24

for.body:                                         ; preds = %for.body, %for.body.preheader.new
  %indvars.iv = phi i64 [ 0, %for.body.preheader.new ], [ %indvars.iv.next.7, %for.body ]
  %s.05 = phi float [ 0.000000e+00, %for.body.preheader.new ], [ %add.7, %for.body ]
  %niter = phi i64 [ 0, %for.body.preheader.new ], [ %niter.next.7, %for.body ]
  %arrayidx = getelementptr inbounds float, ptr %a, i64 %indvars.iv, !dbg !14
  %3 = load float, ptr %arrayidx, align 4, !dbg !14, !tbaa !15
  %add = fadd float %s.05, %3, !dbg !19
  %indvars.iv.next = or i64 %indvars.iv, 1, !dbg !20
  %arrayidx.1 = getelementptr inbounds float, ptr %a, i64 %indvars.iv.next, !dbg !14
  %4 = load float, ptr %arrayidx.1, align 4, !dbg !14, !tbaa !15
  %add.1 = fadd float %add, %4, !dbg !19
  %indvars.iv.next.1 = or i64 %indvars.iv, 2, !dbg !20
  %arrayidx.2 = getelementptr inbounds float, ptr %a, i64 %indvars.iv.next.1, !dbg !14
  %5 = load float, ptr %arrayidx.2, align 4, !dbg !14, !tbaa !15
  %add.2 = fadd float %add.1, %5, !dbg !19
  %indvars.iv.next.2 = or i64 %indvars.iv, 3, !dbg !20
  %arrayidx.3 = getelementptr inbounds float, ptr %a, i64 %indvars.iv.next.2, !dbg !14
  %6 = load float, ptr %arrayidx.3, align 4, !dbg !14, !tbaa !15
  %add.3 = fadd float %add.2, %6, !dbg !19
  %indvars.iv.next.3 = or i64 %indvars.iv, 4, !dbg !20
  %arrayidx.4 = getelementptr inbounds float, ptr %a, i64 %indvars.iv.next.3, !dbg !14
  %7 = load float, ptr %arrayidx.4, align 4, !dbg !14, !tbaa !15
  %add.4 = fadd float %add.3, %7, !dbg !19
  %indvars.iv.next.4 = or i64 %indvars.iv, 5, !dbg !20
  %arrayidx.5 = getelementptr inbounds float, ptr %a, i64 %indvars.iv.next.4, !dbg !14
  %8 = load float, ptr %arrayidx.5, align 4, !dbg !14, !tbaa !15
  %add.5 = fadd float %add.4, %8, !dbg !19
  %indvars.iv.next.5 = or i64 %indvars.iv, 6, !dbg !20
  %arrayidx.6 = getelementptr inbounds float, ptr %a, i64 %indvars.iv.next.5, !dbg !14
  %9 = load float, ptr %arrayidx.6, align 4, !dbg !14, !tbaa !15
  %add.6 = fadd float %add.5, %9, !dbg !19
  %indvars.iv.next.6 = or i64 %indvars.iv, 7, !dbg !20
  %arrayidx.7 = getelementptr inbounds float, ptr %a, i64 %indvars.iv.next.6, !dbg !14
  %10 = load float, ptr %arrayidx.7, align 4, !dbg !14, !tbaa !15
  %add.7 = fadd float %add.6, %10, !dbg !19
  %indvars.iv.next.7 = add nuw nsw i64 %indvars.iv, 8, !dbg !20
  %niter.next.7 = add i64 %niter, 8, !dbg !13
  %niter.ncmp.7 = icmp eq i64 %niter.next.7, %unroll_iter, !dbg !13
  br i1 %niter.ncmp.7, label %for.cond.cleanup.loopexit.unr-lcssa, label %for.body, !dbg !13, !llvm.loop !25
}

; Function Attrs: argmemonly nofree norecurse nosync nounwind readonly uwtable
define dso_local i32 @sum_i32(ptr nocapture noundef readonly %a, i32 noundef %n) local_unnamed_addr #0 !dbg !28 {
entry:
  %cmp4 = icmp sgt i32 %n, 0, !dbg !29
  br i1 %cmp4, label %for.body.preheader, label %for.cond.cleanup, !dbg !30

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !29
  %min.iters.check = icmp ult i32 %n, 8, !dbg !30
  br i1 %min.iters.check, label %for.body.preheader10, label %vector.ph, !dbg !30

vector.ph:                                        ; preds = %for.body.preheader
  %n.vec = and i64 %wide.trip.count, 4294967288, !dbg !30
  %0 = add nsw i64 %n.vec, -8, !dbg !30
  %1 = lshr exact i64 %0, 3, !dbg !30
  %2 = add nuw nsw i64 %1, 1, !dbg !30
  %xtraiter = and i64 %2, 3, !dbg !30
  %3 = icmp ult i64 %0, 24, !dbg !30
  br i1 %3, label %middle.block.unr-lcssa, label %vector.ph.new, !dbg !30

vector.ph.new:                                    ; preds = %vector.ph
  %unroll_iter = and i64 %2, 4611686018427387900, !dbg !30
  br label %vector.body, !dbg !30

vector.body:                                      ; preds = %vector.body, %vector.ph.new
  %index = phi i64 [ 0, %vector.ph.new ], [ %index.next.3, %vector.body ], !dbg !31
  %vec.phi = phi <4 x i32> [ zeroinitializer, %vector.ph.new ], [ %18, %vector.body ]
  %vec.phi8 = phi <4 x i32> [ zeroinitializer, %vector.ph.new ], [ %19, %vector.body ]
  %niter = phi i64 [ 0, %vector.ph.new ], [ %niter.next.3, %vector.body ]
  %4 = getelementptr inbounds i32, ptr %a, i64 %index, !dbg !32
  %wide.load = load <4 x i32>, ptr %4, align 4, !dbg !32, !tbaa !33
  %5 = getelementptr inbounds i32, ptr %4, i64 4, !dbg !32
  %wide.load9 = load <4 x i32>, ptr %5, align 4, !dbg !32, !tbaa !33
  %6 = add <4 x i32> %wide.load, %vec.phi, !dbg !35
  %7 = add <4 x i32> %wide.load9, %vec.phi8, !dbg !35
  %index.next = or i64 %index, 8, !dbg !31
  %8 = getelementptr inbounds i32, ptr %a, i64 %index.next, !dbg !32
  %wide.load.1 = load <4 x i32>, ptr %8, align 4, !dbg !32, !tbaa !33
  %9 = getelementptr inbounds i32, ptr %8, i64 4, !dbg !32
  %wide.load9.1 = load <4 x i32>, ptr %9, align 4, !dbg !32, !tbaa !33
  %10 = add <4 x i32> %wide.load.1, %6, !dbg !35
  %11 = add <4 x i32> %wide.load9.1, %7, !dbg !35
  %index.next.1 = or i64 %index, 16, !dbg !31
  %12 = getelementptr inbounds i32, ptr %a, i64 %index.next.1, !dbg !32
  %wide.load.2 = load <4 x i32>, ptr %12, align 4, !dbg !32, !tbaa !33
  %13 = getelementptr inbounds i32, ptr %12, i64 4, !dbg !32
  %wide.load9.2 = load <4 x i32>, ptr %13, align 4, !dbg !32, !tbaa !33
  %14 = add <4 x i32> %wide.load.2, %10, !dbg !35
  %15 = add <4 x i32> %wide.load9.2, %11, !dbg !35
  %index.next.2 = or i64 %index, 24, !dbg !31
  %16 = getelementptr inbounds i32, ptr %a, i64 %index.next.2, !dbg !32
  %wide.load.3 = load <4 x i32>, ptr %16, align 4, !dbg !32, !tbaa !33
  %17 = getelementptr inbounds i32, ptr %16, i64 4, !dbg !32
  %wide.load9.3 = load <4 x i32>, ptr %17, align 4, !dbg !32, !tbaa !33
  %18 = add <4 x i32> %wide.load.3, %14, !dbg !35
  %19 = add <4 x i32> %wide.load9.3, %15, !dbg !35
  %index.next.3 = add nuw i64 %index, 32, !dbg !31
  %niter.next.3 = add i64 %niter, 4, !dbg !31
  %niter.ncmp.3 = icmp eq i64 %niter.next.3, %unroll_iter, !dbg !31
  br i1 %niter.ncmp.3, label %middle.block.unr-lcssa, label %vector.body, !dbg !31, !llvm.loop !36

middle.block.unr-lcssa:                           ; preds = %vector.body, %vector.ph
  %.lcssa11.ph = phi <4 x i32> [ undef, %vector.ph ], [ %18, %vector.body ]
  %.lcssa.ph = phi <4 x i32> [ undef, %vector.ph ], [ %19, %vector.body ]
  %index.unr = phi i64 [ 0, %vector.ph ], [ %index.next.3, %vector.body ]
  %vec.phi.unr = phi <4 x i32> [ zeroinitializer, %vector.ph ], [ %18, %vector.body ]
  %vec.phi8.unr = phi <4 x i32> [ zeroinitializer, %vector.ph ], [ %19, %vector.body ]
  %lcmp.mod.not = icmp eq i64 %xtraiter, 0, !dbg !31
  br i1 %lcmp.mod.not, label %middle.block, label %vector.body.epil, !dbg !31

vector.body.epil:                                 ; preds = %middle.block.unr-lcssa, %vector.body.epil
  %index.epil = phi i64 [ %index.next.epil, %vector.body.epil ], [ %index.unr, %middle.block.unr-lcssa ], !dbg !31
  %vec.phi.epil = phi <4 x i32> [ %22, %vector.body.epil ], [ %vec.phi.unr, %middle.block.unr-lcssa ]
  %vec.phi8.epil = phi <4 x i32> [ %23, %vector.body.epil ], [ %vec.phi8.unr, %middle.block.unr-lcssa ]
  %epil.iter = phi i64 [ %epil.iter.next, %vector.body.epil ], [ 0, %middle.block.unr-lcssa ]
  %20 = getelementptr inbounds i32, ptr %a, i64 %index.epil, !dbg !32
  %wide.load.epil = load <4 x i32>, ptr %20, align 4, !dbg !32, !tbaa !33
  %21 = getelementptr inbounds i32, ptr %20, i64 4, !dbg !32
  %wide.load9.epil = load <4 x i32>, ptr %21, align 4, !dbg !32, !tbaa !33
  %22 = add <4 x i32> %wide.load.epil, %vec.phi.epil, !dbg !35
  %23 = add <4 x i32> %wide.load9.epil, %vec.phi8.epil, !dbg !35
  %index.next.epil = add nuw i64 %index.epil, 8, !dbg !31
  %epil.iter.next = add i64 %epil.iter, 1, !dbg !31
  %epil.iter.cmp.not = icmp eq i64 %epil.iter.next, %xtraiter, !dbg !31
  br i1 %epil.iter.cmp.not, label %middle.block, label %vector.body.epil, !dbg !31, !llvm.loop !39

middle.block:                                     ; preds = %vector.body.epil, %middle.block.unr-lcssa
  %.lcssa11 = phi <4 x i32> [ %.lcssa11.ph, %middle.block.unr-lcssa ], [ %22, %vector.body.epil ], !dbg !35
  %.lcssa = phi <4 x i32> [ %.lcssa.ph, %middle.block.unr-lcssa ], [ %23, %vector.body.epil ], !dbg !35
  %bin.rdx = add <4 x i32> %.lcssa, %.lcssa11, !dbg !30
  %24 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %bin.rdx), !dbg !30
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count, !dbg !30
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader10, !dbg !30

for.body.preheader10:                             ; preds = %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  %s.05.ph = phi i32 [ 0, %for.body.preheader ], [ %24, %middle.block ]
  br label %for.body, !dbg !30

for.cond.cleanup:                                 ; preds = %for.body, %middle.block, %entry
  %s.0.lcssa = phi i32 [ 0, %entry ], [ %24, %middle.block ], [ %add, %for.body ], !dbg !40
  ret i32 %s.0.lcssa, !dbg !41

for.body:                                         ; preds = %for.body.preheader10, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ %indvars.iv.ph, %for.body.preheader10 ]
  %s.05 = phi i32 [ %add, %for.body ], [ %s.05.ph, %for.body.preheader10 ]
  %arrayidx = getelementptr inbounds i32, ptr %a, i64 %indvars.iv, !dbg !32
  %25 = load i32, ptr %arrayidx, align 4, !dbg !32, !tbaa !33
  %add = add nsw i32 %25, %s.05, !dbg !35
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !31
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !29
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !30, !llvm.loop !42
}

; Function Attrs: nocallback nofree nosync nounwind readnone willreturn
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>) #1

attributes #0 = { argmemonly nofree norecurse nosync nounwind readonly uwtable "frame-pointer"="none" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind readnone willreturn }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7}
!llvm.ident = !{!8}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "Homebrew clang version 15.0.7", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "reduction.c", directory: ".", checksumkind: CSK_MD5, checksum: "01a6d431a8034b1497b56d031f8c3d1a")
!2 = !{i32 7, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 7, !"PIC Level", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{i32 7, !"uwtable", i32 2}
!8 = !{!"Homebrew clang version 15.0.7"}
!9 = distinct !DISubprogram(name: "sum_f32", scope: !1, file: !1, line: 2, type: !10, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !11)
!10 = !DISubroutineType(types: !11)
!11 = !{}
!12 = !DILocation(line: 4, column: 21, scope: !9)
!13 = !DILocation(line: 4, column: 3, scope: !9)
!14 = !DILocation(line: 5, column: 10, scope: !9)
!15 = !{!16, !16, i64 0}
!16 = !{!"float", !17, i64 0}
!17 = !{!"omnipotent char", !18, i64 0}
!18 = !{!"Simple C/C++ TBAA"}
!19 = !DILocation(line: 5, column: 7, scope: !9)
!20 = !DILocation(line: 4, column: 26, scope: !9)
!21 = distinct !{!21, !22}
!22 = !{!"llvm.loop.unroll.disable"}
!23 = !DILocation(line: 0, scope: !9)
!24 = !DILocation(line: 6, column: 3, scope: !9)
!25 = distinct !{!25, !13, !26, !27}
!26 = !DILocation(line: 5, column: 13, scope: !9)
!27 = !{!"llvm.loop.mustprogress"}
!28 = distinct !DISubprogram(name: "sum_i32", scope: !1, file: !1, line: 10, type: !10, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !11)
!29 = !DILocation(line: 12, column: 21, scope: !28)
!30 = !DILocation(line: 12, column: 3, scope: !28)
!31 = !DILocation(line: 12, column: 26, scope: !28)
!32 = !DILocation(line: 13, column: 10, scope: !28)
!33 = !{!34, !34, i64 0}
!34 = !{!"int", !17, i64 0}
!35 = !DILocation(line: 13, column: 7, scope: !28)
!36 = distinct !{!36, !30, !37, !27, !38}
!37 = !DILocation(line: 13, column: 13, scope: !28)
!38 = !{!"llvm.loop.isvectorized", i32 1}
!39 = distinct !{!39, !22}
!40 = !DILocation(line: 0, scope: !28)
!41 = !DILocation(line: 14, column: 3, scope: !28)
!42 = distinct !{!42, !30, !37, !27, !43, !38}
!43 = !{!"llvm.loop.unroll.runtime.disable"}
