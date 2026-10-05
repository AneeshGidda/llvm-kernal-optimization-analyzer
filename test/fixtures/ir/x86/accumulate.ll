; ModuleID = 'accumulate.c'
source_filename = "accumulate.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: argmemonly nofree norecurse nosync nounwind uwtable
define dso_local void @accumulate(ptr nocapture noundef %out, ptr nocapture noundef readonly %a, i32 noundef %n) local_unnamed_addr #0 !dbg !9 {
entry:
  %cmp3 = icmp sgt i32 %n, 0, !dbg !12
  br i1 %cmp3, label %for.body.preheader, label %for.cond.cleanup, !dbg !13

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !12
  %.pre = load float, ptr %out, align 4, !dbg !14, !tbaa !15
  %0 = add nsw i64 %wide.trip.count, -1, !dbg !13
  %xtraiter = and i64 %wide.trip.count, 3, !dbg !13
  %1 = icmp ult i64 %0, 3, !dbg !13
  br i1 %1, label %for.cond.cleanup.loopexit.unr-lcssa, label %for.body.preheader.new, !dbg !13

for.body.preheader.new:                           ; preds = %for.body.preheader
  %unroll_iter = and i64 %wide.trip.count, 4294967292, !dbg !13
  br label %for.body, !dbg !13

for.cond.cleanup.loopexit.unr-lcssa:              ; preds = %for.body, %for.body.preheader
  %.unr = phi float [ %.pre, %for.body.preheader ], [ %add.3, %for.body ]
  %indvars.iv.unr = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next.3, %for.body ]
  %lcmp.mod.not = icmp eq i64 %xtraiter, 0, !dbg !13
  br i1 %lcmp.mod.not, label %for.cond.cleanup, label %for.body.epil, !dbg !13

for.body.epil:                                    ; preds = %for.cond.cleanup.loopexit.unr-lcssa, %for.body.epil
  %2 = phi float [ %add.epil, %for.body.epil ], [ %.unr, %for.cond.cleanup.loopexit.unr-lcssa ], !dbg !14
  %indvars.iv.epil = phi i64 [ %indvars.iv.next.epil, %for.body.epil ], [ %indvars.iv.unr, %for.cond.cleanup.loopexit.unr-lcssa ]
  %epil.iter = phi i64 [ %epil.iter.next, %for.body.epil ], [ 0, %for.cond.cleanup.loopexit.unr-lcssa ]
  %arrayidx.epil = getelementptr inbounds float, ptr %a, i64 %indvars.iv.epil, !dbg !19
  %3 = load float, ptr %arrayidx.epil, align 4, !dbg !19, !tbaa !15
  %add.epil = fadd float %3, %2, !dbg !14
  store float %add.epil, ptr %out, align 4, !dbg !14, !tbaa !15
  %indvars.iv.next.epil = add nuw nsw i64 %indvars.iv.epil, 1, !dbg !20
  %epil.iter.next = add i64 %epil.iter, 1, !dbg !13
  %epil.iter.cmp.not = icmp eq i64 %epil.iter.next, %xtraiter, !dbg !13
  br i1 %epil.iter.cmp.not, label %for.cond.cleanup, label %for.body.epil, !dbg !13, !llvm.loop !21

for.cond.cleanup:                                 ; preds = %for.cond.cleanup.loopexit.unr-lcssa, %for.body.epil, %entry
  ret void, !dbg !23

for.body:                                         ; preds = %for.body, %for.body.preheader.new
  %4 = phi float [ %.pre, %for.body.preheader.new ], [ %add.3, %for.body ], !dbg !14
  %indvars.iv = phi i64 [ 0, %for.body.preheader.new ], [ %indvars.iv.next.3, %for.body ]
  %niter = phi i64 [ 0, %for.body.preheader.new ], [ %niter.next.3, %for.body ]
  %arrayidx = getelementptr inbounds float, ptr %a, i64 %indvars.iv, !dbg !19
  %5 = load float, ptr %arrayidx, align 4, !dbg !19, !tbaa !15
  %add = fadd float %5, %4, !dbg !14
  store float %add, ptr %out, align 4, !dbg !14, !tbaa !15
  %indvars.iv.next = or i64 %indvars.iv, 1, !dbg !20
  %arrayidx.1 = getelementptr inbounds float, ptr %a, i64 %indvars.iv.next, !dbg !19
  %6 = load float, ptr %arrayidx.1, align 4, !dbg !19, !tbaa !15
  %add.1 = fadd float %6, %add, !dbg !14
  store float %add.1, ptr %out, align 4, !dbg !14, !tbaa !15
  %indvars.iv.next.1 = or i64 %indvars.iv, 2, !dbg !20
  %arrayidx.2 = getelementptr inbounds float, ptr %a, i64 %indvars.iv.next.1, !dbg !19
  %7 = load float, ptr %arrayidx.2, align 4, !dbg !19, !tbaa !15
  %add.2 = fadd float %7, %add.1, !dbg !14
  store float %add.2, ptr %out, align 4, !dbg !14, !tbaa !15
  %indvars.iv.next.2 = or i64 %indvars.iv, 3, !dbg !20
  %arrayidx.3 = getelementptr inbounds float, ptr %a, i64 %indvars.iv.next.2, !dbg !19
  %8 = load float, ptr %arrayidx.3, align 4, !dbg !19, !tbaa !15
  %add.3 = fadd float %8, %add.2, !dbg !14
  store float %add.3, ptr %out, align 4, !dbg !14, !tbaa !15
  %indvars.iv.next.3 = add nuw nsw i64 %indvars.iv, 4, !dbg !20
  %niter.next.3 = add i64 %niter, 4, !dbg !13
  %niter.ncmp.3 = icmp eq i64 %niter.next.3, %unroll_iter, !dbg !13
  br i1 %niter.ncmp.3, label %for.cond.cleanup.loopexit.unr-lcssa, label %for.body, !dbg !13, !llvm.loop !24
}

; Function Attrs: argmemonly nofree norecurse nosync nounwind uwtable
define dso_local void @scale_by_ptr(ptr nocapture noundef %y, ptr nocapture noundef readonly %scale, i32 noundef %n) local_unnamed_addr #0 !dbg !27 {
entry:
  %cmp7 = icmp sgt i32 %n, 0, !dbg !28
  br i1 %cmp7, label %for.body.preheader, label %for.cond.cleanup, !dbg !29

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !28
  %min.iters.check = icmp ult i32 %n, 8, !dbg !29
  br i1 %min.iters.check, label %for.body.preheader14, label %vector.memcheck, !dbg !29

vector.memcheck:                                  ; preds = %for.body.preheader
  %0 = shl nuw nsw i64 %wide.trip.count, 2, !dbg !29
  %uglygep = getelementptr i8, ptr %y, i64 %0, !dbg !29
  %uglygep10 = getelementptr i8, ptr %scale, i64 4, !dbg !29
  %bound0 = icmp ugt ptr %uglygep10, %y, !dbg !29
  %bound1 = icmp ugt ptr %uglygep, %scale, !dbg !29
  %found.conflict = and i1 %bound0, %bound1, !dbg !29
  br i1 %found.conflict, label %for.body.preheader14, label %vector.ph, !dbg !29

vector.ph:                                        ; preds = %vector.memcheck
  %n.vec = and i64 %wide.trip.count, 4294967288, !dbg !29
  %1 = add nsw i64 %n.vec, -8, !dbg !29
  %2 = lshr exact i64 %1, 3, !dbg !29
  %3 = add nuw nsw i64 %2, 1, !dbg !29
  %xtraiter = and i64 %3, 1, !dbg !29
  %4 = icmp eq i64 %1, 0, !dbg !29
  br i1 %4, label %middle.block.unr-lcssa, label %vector.ph.new, !dbg !29

vector.ph.new:                                    ; preds = %vector.ph
  %unroll_iter = and i64 %3, 4611686018427387902, !dbg !29
  %5 = load float, ptr %scale, align 4, !tbaa !15, !alias.scope !30
  %broadcast.splatinsert = insertelement <4 x float> poison, float %5, i64 0
  %broadcast.splat = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <4 x i32> zeroinitializer
  %broadcast.splatinsert12 = insertelement <4 x float> poison, float %5, i64 0
  %broadcast.splat13 = shufflevector <4 x float> %broadcast.splatinsert12, <4 x float> poison, <4 x i32> zeroinitializer
  %6 = load float, ptr %scale, align 4, !tbaa !15, !alias.scope !30
  %broadcast.splatinsert.1 = insertelement <4 x float> poison, float %6, i64 0
  %broadcast.splat.1 = shufflevector <4 x float> %broadcast.splatinsert.1, <4 x float> poison, <4 x i32> zeroinitializer
  %broadcast.splatinsert12.1 = insertelement <4 x float> poison, float %6, i64 0
  %broadcast.splat13.1 = shufflevector <4 x float> %broadcast.splatinsert12.1, <4 x float> poison, <4 x i32> zeroinitializer
  br label %vector.body, !dbg !29

vector.body:                                      ; preds = %vector.body, %vector.ph.new
  %index = phi i64 [ 0, %vector.ph.new ], [ %index.next.1, %vector.body ], !dbg !33
  %niter = phi i64 [ 0, %vector.ph.new ], [ %niter.next.1, %vector.body ]
  %7 = getelementptr inbounds float, ptr %y, i64 %index, !dbg !34
  %wide.load = load <4 x float>, ptr %7, align 4, !dbg !34, !tbaa !15, !alias.scope !35, !noalias !30
  %8 = getelementptr inbounds float, ptr %7, i64 4, !dbg !34
  %wide.load11 = load <4 x float>, ptr %8, align 4, !dbg !34, !tbaa !15, !alias.scope !35, !noalias !30
  %9 = fmul <4 x float> %wide.load, %broadcast.splat, !dbg !29
  %10 = fmul <4 x float> %wide.load11, %broadcast.splat13, !dbg !29
  store <4 x float> %9, ptr %7, align 4, !dbg !37, !tbaa !15, !alias.scope !35, !noalias !30
  store <4 x float> %10, ptr %8, align 4, !dbg !37, !tbaa !15, !alias.scope !35, !noalias !30
  %index.next = or i64 %index, 8, !dbg !33
  %11 = getelementptr inbounds float, ptr %y, i64 %index.next, !dbg !34
  %wide.load.1 = load <4 x float>, ptr %11, align 4, !dbg !34, !tbaa !15, !alias.scope !35, !noalias !30
  %12 = getelementptr inbounds float, ptr %11, i64 4, !dbg !34
  %wide.load11.1 = load <4 x float>, ptr %12, align 4, !dbg !34, !tbaa !15, !alias.scope !35, !noalias !30
  %13 = fmul <4 x float> %wide.load.1, %broadcast.splat.1, !dbg !29
  %14 = fmul <4 x float> %wide.load11.1, %broadcast.splat13.1, !dbg !29
  store <4 x float> %13, ptr %11, align 4, !dbg !37, !tbaa !15, !alias.scope !35, !noalias !30
  store <4 x float> %14, ptr %12, align 4, !dbg !37, !tbaa !15, !alias.scope !35, !noalias !30
  %index.next.1 = add nuw i64 %index, 16, !dbg !33
  %niter.next.1 = add i64 %niter, 2, !dbg !33
  %niter.ncmp.1 = icmp eq i64 %niter.next.1, %unroll_iter, !dbg !33
  br i1 %niter.ncmp.1, label %middle.block.unr-lcssa, label %vector.body, !dbg !33, !llvm.loop !38

middle.block.unr-lcssa:                           ; preds = %vector.body, %vector.ph
  %index.unr = phi i64 [ 0, %vector.ph ], [ %index.next.1, %vector.body ]
  %lcmp.mod.not = icmp eq i64 %xtraiter, 0, !dbg !33
  br i1 %lcmp.mod.not, label %middle.block, label %vector.body.epil, !dbg !33

vector.body.epil:                                 ; preds = %middle.block.unr-lcssa
  %15 = getelementptr inbounds float, ptr %y, i64 %index.unr, !dbg !34
  %wide.load.epil = load <4 x float>, ptr %15, align 4, !dbg !34, !tbaa !15, !alias.scope !35, !noalias !30
  %16 = getelementptr inbounds float, ptr %15, i64 4, !dbg !34
  %wide.load11.epil = load <4 x float>, ptr %16, align 4, !dbg !34, !tbaa !15, !alias.scope !35, !noalias !30
  %17 = load float, ptr %scale, align 4, !dbg !41, !tbaa !15, !alias.scope !30
  %broadcast.splatinsert.epil = insertelement <4 x float> poison, float %17, i64 0, !dbg !41
  %broadcast.splat.epil = shufflevector <4 x float> %broadcast.splatinsert.epil, <4 x float> poison, <4 x i32> zeroinitializer, !dbg !41
  %broadcast.splatinsert12.epil = insertelement <4 x float> poison, float %17, i64 0, !dbg !29
  %broadcast.splat13.epil = shufflevector <4 x float> %broadcast.splatinsert12.epil, <4 x float> poison, <4 x i32> zeroinitializer, !dbg !29
  %18 = fmul <4 x float> %wide.load.epil, %broadcast.splat.epil, !dbg !29
  %19 = fmul <4 x float> %wide.load11.epil, %broadcast.splat13.epil, !dbg !29
  store <4 x float> %18, ptr %15, align 4, !dbg !37, !tbaa !15, !alias.scope !35, !noalias !30
  store <4 x float> %19, ptr %16, align 4, !dbg !37, !tbaa !15, !alias.scope !35, !noalias !30
  br label %middle.block, !dbg !29

middle.block:                                     ; preds = %middle.block.unr-lcssa, %vector.body.epil
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count, !dbg !29
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader14, !dbg !29

for.body.preheader14:                             ; preds = %vector.memcheck, %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %vector.memcheck ], [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  %20 = xor i64 %indvars.iv.ph, -1, !dbg !29
  %21 = add nsw i64 %20, %wide.trip.count, !dbg !29
  %xtraiter15 = and i64 %wide.trip.count, 3, !dbg !29
  %lcmp.mod16.not = icmp eq i64 %xtraiter15, 0, !dbg !29
  br i1 %lcmp.mod16.not, label %for.body.prol.loopexit, label %for.body.prol, !dbg !29

for.body.prol:                                    ; preds = %for.body.preheader14, %for.body.prol
  %indvars.iv.prol = phi i64 [ %indvars.iv.next.prol, %for.body.prol ], [ %indvars.iv.ph, %for.body.preheader14 ]
  %prol.iter = phi i64 [ %prol.iter.next, %for.body.prol ], [ 0, %for.body.preheader14 ]
  %arrayidx.prol = getelementptr inbounds float, ptr %y, i64 %indvars.iv.prol, !dbg !34
  %22 = load float, ptr %arrayidx.prol, align 4, !dbg !34, !tbaa !15
  %23 = load float, ptr %scale, align 4, !dbg !41, !tbaa !15
  %mul.prol = fmul float %22, %23, !dbg !42
  store float %mul.prol, ptr %arrayidx.prol, align 4, !dbg !37, !tbaa !15
  %indvars.iv.next.prol = add nuw nsw i64 %indvars.iv.prol, 1, !dbg !33
  %prol.iter.next = add i64 %prol.iter, 1, !dbg !29
  %prol.iter.cmp.not = icmp eq i64 %prol.iter.next, %xtraiter15, !dbg !29
  br i1 %prol.iter.cmp.not, label %for.body.prol.loopexit, label %for.body.prol, !dbg !29, !llvm.loop !43

for.body.prol.loopexit:                           ; preds = %for.body.prol, %for.body.preheader14
  %indvars.iv.unr = phi i64 [ %indvars.iv.ph, %for.body.preheader14 ], [ %indvars.iv.next.prol, %for.body.prol ]
  %24 = icmp ult i64 %21, 3, !dbg !29
  br i1 %24, label %for.cond.cleanup, label %for.body, !dbg !29

for.cond.cleanup:                                 ; preds = %for.body.prol.loopexit, %for.body, %middle.block, %entry
  ret void, !dbg !44

for.body:                                         ; preds = %for.body.prol.loopexit, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next.3, %for.body ], [ %indvars.iv.unr, %for.body.prol.loopexit ]
  %arrayidx = getelementptr inbounds float, ptr %y, i64 %indvars.iv, !dbg !34
  %25 = load float, ptr %arrayidx, align 4, !dbg !34, !tbaa !15
  %26 = load float, ptr %scale, align 4, !dbg !41, !tbaa !15
  %mul = fmul float %25, %26, !dbg !42
  store float %mul, ptr %arrayidx, align 4, !dbg !37, !tbaa !15
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !33
  %arrayidx.1 = getelementptr inbounds float, ptr %y, i64 %indvars.iv.next, !dbg !34
  %27 = load float, ptr %arrayidx.1, align 4, !dbg !34, !tbaa !15
  %28 = load float, ptr %scale, align 4, !dbg !41, !tbaa !15
  %mul.1 = fmul float %27, %28, !dbg !42
  store float %mul.1, ptr %arrayidx.1, align 4, !dbg !37, !tbaa !15
  %indvars.iv.next.1 = add nuw nsw i64 %indvars.iv, 2, !dbg !33
  %arrayidx.2 = getelementptr inbounds float, ptr %y, i64 %indvars.iv.next.1, !dbg !34
  %29 = load float, ptr %arrayidx.2, align 4, !dbg !34, !tbaa !15
  %30 = load float, ptr %scale, align 4, !dbg !41, !tbaa !15
  %mul.2 = fmul float %29, %30, !dbg !42
  store float %mul.2, ptr %arrayidx.2, align 4, !dbg !37, !tbaa !15
  %indvars.iv.next.2 = add nuw nsw i64 %indvars.iv, 3, !dbg !33
  %arrayidx.3 = getelementptr inbounds float, ptr %y, i64 %indvars.iv.next.2, !dbg !34
  %31 = load float, ptr %arrayidx.3, align 4, !dbg !34, !tbaa !15
  %32 = load float, ptr %scale, align 4, !dbg !41, !tbaa !15
  %mul.3 = fmul float %31, %32, !dbg !42
  store float %mul.3, ptr %arrayidx.3, align 4, !dbg !37, !tbaa !15
  %indvars.iv.next.3 = add nuw nsw i64 %indvars.iv, 4, !dbg !33
  %exitcond.not.3 = icmp eq i64 %indvars.iv.next.3, %wide.trip.count, !dbg !28
  br i1 %exitcond.not.3, label %for.cond.cleanup, label %for.body, !dbg !29, !llvm.loop !45
}

attributes #0 = { argmemonly nofree norecurse nosync nounwind uwtable "frame-pointer"="none" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7}
!llvm.ident = !{!8}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "Homebrew clang version 15.0.7", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "accumulate.c", directory: ".", checksumkind: CSK_MD5, checksum: "d925018ee4608aa9c7d0b8bca2fe5ff9")
!2 = !{i32 7, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 7, !"PIC Level", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{i32 7, !"uwtable", i32 2}
!8 = !{!"Homebrew clang version 15.0.7"}
!9 = distinct !DISubprogram(name: "accumulate", scope: !1, file: !1, line: 3, type: !10, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !11)
!10 = !DISubroutineType(types: !11)
!11 = !{}
!12 = !DILocation(line: 4, column: 21, scope: !9)
!13 = !DILocation(line: 4, column: 3, scope: !9)
!14 = !DILocation(line: 5, column: 10, scope: !9)
!15 = !{!16, !16, i64 0}
!16 = !{!"float", !17, i64 0}
!17 = !{!"omnipotent char", !18, i64 0}
!18 = !{!"Simple C/C++ TBAA"}
!19 = !DILocation(line: 5, column: 13, scope: !9)
!20 = !DILocation(line: 4, column: 26, scope: !9)
!21 = distinct !{!21, !22}
!22 = !{!"llvm.loop.unroll.disable"}
!23 = !DILocation(line: 6, column: 1, scope: !9)
!24 = distinct !{!24, !13, !25, !26}
!25 = !DILocation(line: 5, column: 16, scope: !9)
!26 = !{!"llvm.loop.mustprogress"}
!27 = distinct !DISubprogram(name: "scale_by_ptr", scope: !1, file: !1, line: 9, type: !10, scopeLine: 9, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !11)
!28 = !DILocation(line: 10, column: 21, scope: !27)
!29 = !DILocation(line: 10, column: 3, scope: !27)
!30 = !{!31}
!31 = distinct !{!31, !32}
!32 = distinct !{!32, !"LVerDomain"}
!33 = !DILocation(line: 10, column: 26, scope: !27)
!34 = !DILocation(line: 11, column: 12, scope: !27)
!35 = !{!36}
!36 = distinct !{!36, !32}
!37 = !DILocation(line: 11, column: 10, scope: !27)
!38 = distinct !{!38, !29, !39, !26, !40}
!39 = !DILocation(line: 11, column: 20, scope: !27)
!40 = !{!"llvm.loop.isvectorized", i32 1}
!41 = !DILocation(line: 11, column: 19, scope: !27)
!42 = !DILocation(line: 11, column: 17, scope: !27)
!43 = distinct !{!43, !22}
!44 = !DILocation(line: 12, column: 1, scope: !27)
!45 = distinct !{!45, !29, !39, !26, !40}
