; ModuleID = 'saxpy.c'
source_filename = "saxpy.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: argmemonly nofree nosync nounwind uwtable
define dso_local void @saxpy(float noundef %a, ptr nocapture noundef readonly %x, ptr nocapture noundef %y, i32 noundef %n) local_unnamed_addr #0 !dbg !9 {
entry:
  %cmp10 = icmp sgt i32 %n, 0, !dbg !12
  br i1 %cmp10, label %for.body.preheader, label %for.cond.cleanup, !dbg !13

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !12
  %min.iters.check = icmp ult i32 %n, 8, !dbg !13
  br i1 %min.iters.check, label %for.body.preheader19, label %vector.memcheck, !dbg !13

vector.memcheck:                                  ; preds = %for.body.preheader
  %0 = shl nuw nsw i64 %wide.trip.count, 2, !dbg !13
  %uglygep = getelementptr i8, ptr %y, i64 %0, !dbg !13
  %uglygep13 = getelementptr i8, ptr %x, i64 %0, !dbg !13
  %bound0 = icmp ugt ptr %uglygep13, %y, !dbg !13
  %bound1 = icmp ugt ptr %uglygep, %x, !dbg !13
  %found.conflict = and i1 %bound0, %bound1, !dbg !13
  br i1 %found.conflict, label %for.body.preheader19, label %vector.ph, !dbg !13

vector.ph:                                        ; preds = %vector.memcheck
  %n.vec = and i64 %wide.trip.count, 4294967288, !dbg !13
  %broadcast.splatinsert = insertelement <4 x float> poison, float %a, i64 0, !dbg !13
  %broadcast.splat = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <4 x i32> zeroinitializer, !dbg !13
  %broadcast.splatinsert17 = insertelement <4 x float> poison, float %a, i64 0, !dbg !13
  %broadcast.splat18 = shufflevector <4 x float> %broadcast.splatinsert17, <4 x float> poison, <4 x i32> zeroinitializer, !dbg !13
  %1 = add nsw i64 %n.vec, -8, !dbg !13
  %2 = lshr exact i64 %1, 3, !dbg !13
  %3 = add nuw nsw i64 %2, 1, !dbg !13
  %xtraiter = and i64 %3, 1, !dbg !13
  %4 = icmp eq i64 %1, 0, !dbg !13
  br i1 %4, label %middle.block.unr-lcssa, label %vector.ph.new, !dbg !13

vector.ph.new:                                    ; preds = %vector.ph
  %unroll_iter = and i64 %3, 4611686018427387902, !dbg !13
  br label %vector.body, !dbg !13

vector.body:                                      ; preds = %vector.body, %vector.ph.new
  %index = phi i64 [ 0, %vector.ph.new ], [ %index.next.1, %vector.body ], !dbg !14
  %niter = phi i64 [ 0, %vector.ph.new ], [ %niter.next.1, %vector.body ]
  %5 = getelementptr inbounds float, ptr %x, i64 %index, !dbg !15
  %wide.load = load <4 x float>, ptr %5, align 4, !dbg !15, !tbaa !16, !alias.scope !20
  %6 = getelementptr inbounds float, ptr %5, i64 4, !dbg !15
  %wide.load14 = load <4 x float>, ptr %6, align 4, !dbg !15, !tbaa !16, !alias.scope !20
  %7 = getelementptr inbounds float, ptr %y, i64 %index, !dbg !23
  %wide.load15 = load <4 x float>, ptr %7, align 4, !dbg !23, !tbaa !16, !alias.scope !24, !noalias !20
  %8 = getelementptr inbounds float, ptr %7, i64 4, !dbg !23
  %wide.load16 = load <4 x float>, ptr %8, align 4, !dbg !23, !tbaa !16, !alias.scope !24, !noalias !20
  %9 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load, <4 x float> %wide.load15), !dbg !26
  %10 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat18, <4 x float> %wide.load14, <4 x float> %wide.load16), !dbg !26
  store <4 x float> %9, ptr %7, align 4, !dbg !27, !tbaa !16, !alias.scope !24, !noalias !20
  store <4 x float> %10, ptr %8, align 4, !dbg !27, !tbaa !16, !alias.scope !24, !noalias !20
  %index.next = or i64 %index, 8, !dbg !14
  %11 = getelementptr inbounds float, ptr %x, i64 %index.next, !dbg !15
  %wide.load.1 = load <4 x float>, ptr %11, align 4, !dbg !15, !tbaa !16, !alias.scope !20
  %12 = getelementptr inbounds float, ptr %11, i64 4, !dbg !15
  %wide.load14.1 = load <4 x float>, ptr %12, align 4, !dbg !15, !tbaa !16, !alias.scope !20
  %13 = getelementptr inbounds float, ptr %y, i64 %index.next, !dbg !23
  %wide.load15.1 = load <4 x float>, ptr %13, align 4, !dbg !23, !tbaa !16, !alias.scope !24, !noalias !20
  %14 = getelementptr inbounds float, ptr %13, i64 4, !dbg !23
  %wide.load16.1 = load <4 x float>, ptr %14, align 4, !dbg !23, !tbaa !16, !alias.scope !24, !noalias !20
  %15 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load.1, <4 x float> %wide.load15.1), !dbg !26
  %16 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat18, <4 x float> %wide.load14.1, <4 x float> %wide.load16.1), !dbg !26
  store <4 x float> %15, ptr %13, align 4, !dbg !27, !tbaa !16, !alias.scope !24, !noalias !20
  store <4 x float> %16, ptr %14, align 4, !dbg !27, !tbaa !16, !alias.scope !24, !noalias !20
  %index.next.1 = add nuw i64 %index, 16, !dbg !14
  %niter.next.1 = add i64 %niter, 2, !dbg !14
  %niter.ncmp.1 = icmp eq i64 %niter.next.1, %unroll_iter, !dbg !14
  br i1 %niter.ncmp.1, label %middle.block.unr-lcssa, label %vector.body, !dbg !14, !llvm.loop !28

middle.block.unr-lcssa:                           ; preds = %vector.body, %vector.ph
  %index.unr = phi i64 [ 0, %vector.ph ], [ %index.next.1, %vector.body ]
  %lcmp.mod.not = icmp eq i64 %xtraiter, 0, !dbg !14
  br i1 %lcmp.mod.not, label %middle.block, label %vector.body.epil, !dbg !14

vector.body.epil:                                 ; preds = %middle.block.unr-lcssa
  %17 = getelementptr inbounds float, ptr %x, i64 %index.unr, !dbg !15
  %wide.load.epil = load <4 x float>, ptr %17, align 4, !dbg !15, !tbaa !16, !alias.scope !20
  %18 = getelementptr inbounds float, ptr %17, i64 4, !dbg !15
  %wide.load14.epil = load <4 x float>, ptr %18, align 4, !dbg !15, !tbaa !16, !alias.scope !20
  %19 = getelementptr inbounds float, ptr %y, i64 %index.unr, !dbg !23
  %wide.load15.epil = load <4 x float>, ptr %19, align 4, !dbg !23, !tbaa !16, !alias.scope !24, !noalias !20
  %20 = getelementptr inbounds float, ptr %19, i64 4, !dbg !23
  %wide.load16.epil = load <4 x float>, ptr %20, align 4, !dbg !23, !tbaa !16, !alias.scope !24, !noalias !20
  %21 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load.epil, <4 x float> %wide.load15.epil), !dbg !26
  %22 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat18, <4 x float> %wide.load14.epil, <4 x float> %wide.load16.epil), !dbg !26
  store <4 x float> %21, ptr %19, align 4, !dbg !27, !tbaa !16, !alias.scope !24, !noalias !20
  store <4 x float> %22, ptr %20, align 4, !dbg !27, !tbaa !16, !alias.scope !24, !noalias !20
  br label %middle.block, !dbg !13

middle.block:                                     ; preds = %middle.block.unr-lcssa, %vector.body.epil
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count, !dbg !13
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader19, !dbg !13

for.body.preheader19:                             ; preds = %vector.memcheck, %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %vector.memcheck ], [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  %23 = xor i64 %indvars.iv.ph, -1, !dbg !13
  %xtraiter20 = and i64 %wide.trip.count, 1, !dbg !13
  %lcmp.mod21.not = icmp eq i64 %xtraiter20, 0, !dbg !13
  br i1 %lcmp.mod21.not, label %for.body.prol.loopexit, label %for.body.prol, !dbg !13

for.body.prol:                                    ; preds = %for.body.preheader19
  %arrayidx.prol = getelementptr inbounds float, ptr %x, i64 %indvars.iv.ph, !dbg !15
  %24 = load float, ptr %arrayidx.prol, align 4, !dbg !15, !tbaa !16
  %arrayidx2.prol = getelementptr inbounds float, ptr %y, i64 %indvars.iv.ph, !dbg !23
  %25 = load float, ptr %arrayidx2.prol, align 4, !dbg !23, !tbaa !16
  %26 = tail call float @llvm.fmuladd.f32(float %a, float %24, float %25), !dbg !26
  store float %26, ptr %arrayidx2.prol, align 4, !dbg !27, !tbaa !16
  %indvars.iv.next.prol = or i64 %indvars.iv.ph, 1, !dbg !14
  br label %for.body.prol.loopexit, !dbg !13

for.body.prol.loopexit:                           ; preds = %for.body.prol, %for.body.preheader19
  %indvars.iv.unr = phi i64 [ %indvars.iv.ph, %for.body.preheader19 ], [ %indvars.iv.next.prol, %for.body.prol ]
  %27 = sub nsw i64 0, %wide.trip.count, !dbg !13
  %28 = icmp eq i64 %23, %27, !dbg !13
  br i1 %28, label %for.cond.cleanup, label %for.body, !dbg !13

for.cond.cleanup:                                 ; preds = %for.body.prol.loopexit, %for.body, %middle.block, %entry
  ret void, !dbg !32

for.body:                                         ; preds = %for.body.prol.loopexit, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next.1, %for.body ], [ %indvars.iv.unr, %for.body.prol.loopexit ]
  %arrayidx = getelementptr inbounds float, ptr %x, i64 %indvars.iv, !dbg !15
  %29 = load float, ptr %arrayidx, align 4, !dbg !15, !tbaa !16
  %arrayidx2 = getelementptr inbounds float, ptr %y, i64 %indvars.iv, !dbg !23
  %30 = load float, ptr %arrayidx2, align 4, !dbg !23, !tbaa !16
  %31 = tail call float @llvm.fmuladd.f32(float %a, float %29, float %30), !dbg !26
  store float %31, ptr %arrayidx2, align 4, !dbg !27, !tbaa !16
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !14
  %arrayidx.1 = getelementptr inbounds float, ptr %x, i64 %indvars.iv.next, !dbg !15
  %32 = load float, ptr %arrayidx.1, align 4, !dbg !15, !tbaa !16
  %arrayidx2.1 = getelementptr inbounds float, ptr %y, i64 %indvars.iv.next, !dbg !23
  %33 = load float, ptr %arrayidx2.1, align 4, !dbg !23, !tbaa !16
  %34 = tail call float @llvm.fmuladd.f32(float %a, float %32, float %33), !dbg !26
  store float %34, ptr %arrayidx2.1, align 4, !dbg !27, !tbaa !16
  %indvars.iv.next.1 = add nuw nsw i64 %indvars.iv, 2, !dbg !14
  %exitcond.not.1 = icmp eq i64 %indvars.iv.next.1, %wide.trip.count, !dbg !12
  br i1 %exitcond.not.1, label %for.cond.cleanup, label %for.body, !dbg !13, !llvm.loop !33
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare float @llvm.fmuladd.f32(float, float, float) #1

; Function Attrs: argmemonly nofree nosync nounwind uwtable
define dso_local void @saxpy_restrict(float noundef %a, ptr noalias nocapture noundef readonly %x, ptr noalias nocapture noundef %y, i32 noundef %n) local_unnamed_addr #0 !dbg !34 {
entry:
  %cmp10 = icmp sgt i32 %n, 0, !dbg !35
  br i1 %cmp10, label %for.body.preheader, label %for.cond.cleanup, !dbg !36

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !35
  %min.iters.check = icmp ult i32 %n, 8, !dbg !36
  br i1 %min.iters.check, label %for.body.preheader18, label %vector.ph, !dbg !36

vector.ph:                                        ; preds = %for.body.preheader
  %n.vec = and i64 %wide.trip.count, 4294967288, !dbg !36
  %broadcast.splatinsert = insertelement <4 x float> poison, float %a, i64 0, !dbg !36
  %broadcast.splat = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <4 x i32> zeroinitializer, !dbg !36
  %broadcast.splatinsert16 = insertelement <4 x float> poison, float %a, i64 0, !dbg !36
  %broadcast.splat17 = shufflevector <4 x float> %broadcast.splatinsert16, <4 x float> poison, <4 x i32> zeroinitializer, !dbg !36
  %0 = add nsw i64 %n.vec, -8, !dbg !36
  %1 = lshr exact i64 %0, 3, !dbg !36
  %2 = add nuw nsw i64 %1, 1, !dbg !36
  %xtraiter = and i64 %2, 1, !dbg !36
  %3 = icmp eq i64 %0, 0, !dbg !36
  br i1 %3, label %middle.block.unr-lcssa, label %vector.ph.new, !dbg !36

vector.ph.new:                                    ; preds = %vector.ph
  %unroll_iter = and i64 %2, 4611686018427387902, !dbg !36
  br label %vector.body, !dbg !36

vector.body:                                      ; preds = %vector.body, %vector.ph.new
  %index = phi i64 [ 0, %vector.ph.new ], [ %index.next.1, %vector.body ], !dbg !37
  %niter = phi i64 [ 0, %vector.ph.new ], [ %niter.next.1, %vector.body ]
  %4 = getelementptr inbounds float, ptr %x, i64 %index, !dbg !38
  %wide.load = load <4 x float>, ptr %4, align 4, !dbg !38, !tbaa !16
  %5 = getelementptr inbounds float, ptr %4, i64 4, !dbg !38
  %wide.load13 = load <4 x float>, ptr %5, align 4, !dbg !38, !tbaa !16
  %6 = getelementptr inbounds float, ptr %y, i64 %index, !dbg !39
  %wide.load14 = load <4 x float>, ptr %6, align 4, !dbg !39, !tbaa !16
  %7 = getelementptr inbounds float, ptr %6, i64 4, !dbg !39
  %wide.load15 = load <4 x float>, ptr %7, align 4, !dbg !39, !tbaa !16
  %8 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load, <4 x float> %wide.load14), !dbg !40
  %9 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat17, <4 x float> %wide.load13, <4 x float> %wide.load15), !dbg !40
  store <4 x float> %8, ptr %6, align 4, !dbg !41, !tbaa !16
  store <4 x float> %9, ptr %7, align 4, !dbg !41, !tbaa !16
  %index.next = or i64 %index, 8, !dbg !37
  %10 = getelementptr inbounds float, ptr %x, i64 %index.next, !dbg !38
  %wide.load.1 = load <4 x float>, ptr %10, align 4, !dbg !38, !tbaa !16
  %11 = getelementptr inbounds float, ptr %10, i64 4, !dbg !38
  %wide.load13.1 = load <4 x float>, ptr %11, align 4, !dbg !38, !tbaa !16
  %12 = getelementptr inbounds float, ptr %y, i64 %index.next, !dbg !39
  %wide.load14.1 = load <4 x float>, ptr %12, align 4, !dbg !39, !tbaa !16
  %13 = getelementptr inbounds float, ptr %12, i64 4, !dbg !39
  %wide.load15.1 = load <4 x float>, ptr %13, align 4, !dbg !39, !tbaa !16
  %14 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load.1, <4 x float> %wide.load14.1), !dbg !40
  %15 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat17, <4 x float> %wide.load13.1, <4 x float> %wide.load15.1), !dbg !40
  store <4 x float> %14, ptr %12, align 4, !dbg !41, !tbaa !16
  store <4 x float> %15, ptr %13, align 4, !dbg !41, !tbaa !16
  %index.next.1 = add nuw i64 %index, 16, !dbg !37
  %niter.next.1 = add i64 %niter, 2, !dbg !37
  %niter.ncmp.1 = icmp eq i64 %niter.next.1, %unroll_iter, !dbg !37
  br i1 %niter.ncmp.1, label %middle.block.unr-lcssa, label %vector.body, !dbg !37, !llvm.loop !42

middle.block.unr-lcssa:                           ; preds = %vector.body, %vector.ph
  %index.unr = phi i64 [ 0, %vector.ph ], [ %index.next.1, %vector.body ]
  %lcmp.mod.not = icmp eq i64 %xtraiter, 0, !dbg !37
  br i1 %lcmp.mod.not, label %middle.block, label %vector.body.epil, !dbg !37

vector.body.epil:                                 ; preds = %middle.block.unr-lcssa
  %16 = getelementptr inbounds float, ptr %x, i64 %index.unr, !dbg !38
  %wide.load.epil = load <4 x float>, ptr %16, align 4, !dbg !38, !tbaa !16
  %17 = getelementptr inbounds float, ptr %16, i64 4, !dbg !38
  %wide.load13.epil = load <4 x float>, ptr %17, align 4, !dbg !38, !tbaa !16
  %18 = getelementptr inbounds float, ptr %y, i64 %index.unr, !dbg !39
  %wide.load14.epil = load <4 x float>, ptr %18, align 4, !dbg !39, !tbaa !16
  %19 = getelementptr inbounds float, ptr %18, i64 4, !dbg !39
  %wide.load15.epil = load <4 x float>, ptr %19, align 4, !dbg !39, !tbaa !16
  %20 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load.epil, <4 x float> %wide.load14.epil), !dbg !40
  %21 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat17, <4 x float> %wide.load13.epil, <4 x float> %wide.load15.epil), !dbg !40
  store <4 x float> %20, ptr %18, align 4, !dbg !41, !tbaa !16
  store <4 x float> %21, ptr %19, align 4, !dbg !41, !tbaa !16
  br label %middle.block, !dbg !36

middle.block:                                     ; preds = %middle.block.unr-lcssa, %vector.body.epil
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count, !dbg !36
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader18, !dbg !36

for.body.preheader18:                             ; preds = %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  br label %for.body, !dbg !36

for.cond.cleanup:                                 ; preds = %for.body, %middle.block, %entry
  ret void, !dbg !44

for.body:                                         ; preds = %for.body.preheader18, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ %indvars.iv.ph, %for.body.preheader18 ]
  %arrayidx = getelementptr inbounds float, ptr %x, i64 %indvars.iv, !dbg !38
  %22 = load float, ptr %arrayidx, align 4, !dbg !38, !tbaa !16
  %arrayidx2 = getelementptr inbounds float, ptr %y, i64 %indvars.iv, !dbg !39
  %23 = load float, ptr %arrayidx2, align 4, !dbg !39, !tbaa !16
  %24 = tail call float @llvm.fmuladd.f32(float %a, float %22, float %23), !dbg !40
  store float %24, ptr %arrayidx2, align 4, !dbg !41, !tbaa !16
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !37
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !35
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !36, !llvm.loop !45
}

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare <4 x float> @llvm.fmuladd.v4f32(<4 x float>, <4 x float>, <4 x float>) #2

attributes #0 = { argmemonly nofree nosync nounwind uwtable "frame-pointer"="none" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn }
attributes #2 = { nocallback nofree nosync nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7}
!llvm.ident = !{!8}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "Homebrew clang version 15.0.7", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "saxpy.c", directory: ".", checksumkind: CSK_MD5, checksum: "1483ec023833ab48a9601b892cc03f9b")
!2 = !{i32 7, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 7, !"PIC Level", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{i32 7, !"uwtable", i32 2}
!8 = !{!"Homebrew clang version 15.0.7"}
!9 = distinct !DISubprogram(name: "saxpy", scope: !1, file: !1, line: 2, type: !10, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !11)
!10 = !DISubroutineType(types: !11)
!11 = !{}
!12 = !DILocation(line: 3, column: 21, scope: !9)
!13 = !DILocation(line: 3, column: 3, scope: !9)
!14 = !DILocation(line: 3, column: 26, scope: !9)
!15 = !DILocation(line: 4, column: 16, scope: !9)
!16 = !{!17, !17, i64 0}
!17 = !{!"float", !18, i64 0}
!18 = !{!"omnipotent char", !19, i64 0}
!19 = !{!"Simple C/C++ TBAA"}
!20 = !{!21}
!21 = distinct !{!21, !22}
!22 = distinct !{!22, !"LVerDomain"}
!23 = !DILocation(line: 4, column: 23, scope: !9)
!24 = !{!25}
!25 = distinct !{!25, !22}
!26 = !DILocation(line: 4, column: 21, scope: !9)
!27 = !DILocation(line: 4, column: 10, scope: !9)
!28 = distinct !{!28, !13, !29, !30, !31}
!29 = !DILocation(line: 4, column: 26, scope: !9)
!30 = !{!"llvm.loop.mustprogress"}
!31 = !{!"llvm.loop.isvectorized", i32 1}
!32 = !DILocation(line: 5, column: 1, scope: !9)
!33 = distinct !{!33, !13, !29, !30, !31}
!34 = distinct !DISubprogram(name: "saxpy_restrict", scope: !1, file: !1, line: 8, type: !10, scopeLine: 8, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !11)
!35 = !DILocation(line: 9, column: 21, scope: !34)
!36 = !DILocation(line: 9, column: 3, scope: !34)
!37 = !DILocation(line: 9, column: 26, scope: !34)
!38 = !DILocation(line: 10, column: 16, scope: !34)
!39 = !DILocation(line: 10, column: 23, scope: !34)
!40 = !DILocation(line: 10, column: 21, scope: !34)
!41 = !DILocation(line: 10, column: 10, scope: !34)
!42 = distinct !{!42, !36, !43, !30, !31}
!43 = !DILocation(line: 10, column: 26, scope: !34)
!44 = !DILocation(line: 11, column: 1, scope: !34)
!45 = distinct !{!45, !36, !43, !30, !46, !31}
!46 = !{!"llvm.loop.unroll.runtime.disable"}
