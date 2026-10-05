; ModuleID = 'saxpy.c'
source_filename = "saxpy.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree nosync nounwind ssp uwtable
define void @saxpy(float noundef %a, ptr nocapture noundef readonly %x, ptr nocapture noundef %y, i32 noundef %n) local_unnamed_addr #0 !dbg !10 {
entry:
  %cmp10 = icmp sgt i32 %n, 0, !dbg !13
  br i1 %cmp10, label %for.body.preheader, label %for.cond.cleanup, !dbg !14

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !13
  %min.iters.check = icmp ult i32 %n, 8, !dbg !14
  br i1 %min.iters.check, label %for.body.preheader19, label %vector.memcheck, !dbg !14

vector.memcheck:                                  ; preds = %for.body.preheader
  %0 = shl nuw nsw i64 %wide.trip.count, 2, !dbg !14
  %uglygep = getelementptr i8, ptr %y, i64 %0, !dbg !14
  %uglygep13 = getelementptr i8, ptr %x, i64 %0, !dbg !14
  %bound0 = icmp ugt ptr %uglygep13, %y, !dbg !14
  %bound1 = icmp ugt ptr %uglygep, %x, !dbg !14
  %found.conflict = and i1 %bound0, %bound1, !dbg !14
  br i1 %found.conflict, label %for.body.preheader19, label %vector.ph, !dbg !14

vector.ph:                                        ; preds = %vector.memcheck
  %n.vec = and i64 %wide.trip.count, 4294967288, !dbg !14
  %broadcast.splatinsert = insertelement <4 x float> poison, float %a, i64 0, !dbg !14
  %broadcast.splat = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <4 x i32> zeroinitializer, !dbg !14
  %broadcast.splatinsert17 = insertelement <4 x float> poison, float %a, i64 0, !dbg !14
  %broadcast.splat18 = shufflevector <4 x float> %broadcast.splatinsert17, <4 x float> poison, <4 x i32> zeroinitializer, !dbg !14
  br label %vector.body, !dbg !14

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ], !dbg !15
  %1 = getelementptr inbounds float, ptr %x, i64 %index, !dbg !16
  %wide.load = load <4 x float>, ptr %1, align 4, !dbg !16, !tbaa !17, !alias.scope !21
  %2 = getelementptr inbounds float, ptr %1, i64 4, !dbg !16
  %wide.load14 = load <4 x float>, ptr %2, align 4, !dbg !16, !tbaa !17, !alias.scope !21
  %3 = getelementptr inbounds float, ptr %y, i64 %index, !dbg !24
  %wide.load15 = load <4 x float>, ptr %3, align 4, !dbg !24, !tbaa !17, !alias.scope !25, !noalias !21
  %4 = getelementptr inbounds float, ptr %3, i64 4, !dbg !24
  %wide.load16 = load <4 x float>, ptr %4, align 4, !dbg !24, !tbaa !17, !alias.scope !25, !noalias !21
  %5 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load, <4 x float> %wide.load15), !dbg !27
  %6 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat18, <4 x float> %wide.load14, <4 x float> %wide.load16), !dbg !27
  store <4 x float> %5, ptr %3, align 4, !dbg !28, !tbaa !17, !alias.scope !25, !noalias !21
  store <4 x float> %6, ptr %4, align 4, !dbg !28, !tbaa !17, !alias.scope !25, !noalias !21
  %index.next = add nuw i64 %index, 8, !dbg !15
  %7 = icmp eq i64 %index.next, %n.vec, !dbg !15
  br i1 %7, label %middle.block, label %vector.body, !dbg !15, !llvm.loop !29

middle.block:                                     ; preds = %vector.body
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count, !dbg !14
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader19, !dbg !14

for.body.preheader19:                             ; preds = %vector.memcheck, %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %vector.memcheck ], [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  br label %for.body, !dbg !14

for.cond.cleanup:                                 ; preds = %for.body, %middle.block, %entry
  ret void, !dbg !33

for.body:                                         ; preds = %for.body.preheader19, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ %indvars.iv.ph, %for.body.preheader19 ]
  %arrayidx = getelementptr inbounds float, ptr %x, i64 %indvars.iv, !dbg !16
  %8 = load float, ptr %arrayidx, align 4, !dbg !16, !tbaa !17
  %arrayidx2 = getelementptr inbounds float, ptr %y, i64 %indvars.iv, !dbg !24
  %9 = load float, ptr %arrayidx2, align 4, !dbg !24, !tbaa !17
  %10 = tail call float @llvm.fmuladd.f32(float %a, float %8, float %9), !dbg !27
  store float %10, ptr %arrayidx2, align 4, !dbg !28, !tbaa !17
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !15
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !13
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !14, !llvm.loop !34
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare float @llvm.fmuladd.f32(float, float, float) #1

; Function Attrs: argmemonly nofree nosync nounwind ssp uwtable
define void @saxpy_restrict(float noundef %a, ptr noalias nocapture noundef readonly %x, ptr noalias nocapture noundef %y, i32 noundef %n) local_unnamed_addr #0 !dbg !35 {
entry:
  %cmp10 = icmp sgt i32 %n, 0, !dbg !36
  br i1 %cmp10, label %for.body.preheader, label %for.cond.cleanup, !dbg !37

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !36
  %min.iters.check = icmp ult i32 %n, 8, !dbg !37
  br i1 %min.iters.check, label %for.body.preheader18, label %vector.ph, !dbg !37

vector.ph:                                        ; preds = %for.body.preheader
  %n.vec = and i64 %wide.trip.count, 4294967288, !dbg !37
  %broadcast.splatinsert = insertelement <4 x float> poison, float %a, i64 0, !dbg !37
  %broadcast.splat = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <4 x i32> zeroinitializer, !dbg !37
  %broadcast.splatinsert16 = insertelement <4 x float> poison, float %a, i64 0, !dbg !37
  %broadcast.splat17 = shufflevector <4 x float> %broadcast.splatinsert16, <4 x float> poison, <4 x i32> zeroinitializer, !dbg !37
  br label %vector.body, !dbg !37

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ], !dbg !38
  %0 = getelementptr inbounds float, ptr %x, i64 %index, !dbg !39
  %wide.load = load <4 x float>, ptr %0, align 4, !dbg !39, !tbaa !17
  %1 = getelementptr inbounds float, ptr %0, i64 4, !dbg !39
  %wide.load13 = load <4 x float>, ptr %1, align 4, !dbg !39, !tbaa !17
  %2 = getelementptr inbounds float, ptr %y, i64 %index, !dbg !40
  %wide.load14 = load <4 x float>, ptr %2, align 4, !dbg !40, !tbaa !17
  %3 = getelementptr inbounds float, ptr %2, i64 4, !dbg !40
  %wide.load15 = load <4 x float>, ptr %3, align 4, !dbg !40, !tbaa !17
  %4 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load, <4 x float> %wide.load14), !dbg !41
  %5 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat17, <4 x float> %wide.load13, <4 x float> %wide.load15), !dbg !41
  store <4 x float> %4, ptr %2, align 4, !dbg !42, !tbaa !17
  store <4 x float> %5, ptr %3, align 4, !dbg !42, !tbaa !17
  %index.next = add nuw i64 %index, 8, !dbg !38
  %6 = icmp eq i64 %index.next, %n.vec, !dbg !38
  br i1 %6, label %middle.block, label %vector.body, !dbg !38, !llvm.loop !43

middle.block:                                     ; preds = %vector.body
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count, !dbg !37
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader18, !dbg !37

for.body.preheader18:                             ; preds = %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  br label %for.body, !dbg !37

for.cond.cleanup:                                 ; preds = %for.body, %middle.block, %entry
  ret void, !dbg !45

for.body:                                         ; preds = %for.body.preheader18, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ %indvars.iv.ph, %for.body.preheader18 ]
  %arrayidx = getelementptr inbounds float, ptr %x, i64 %indvars.iv, !dbg !39
  %7 = load float, ptr %arrayidx, align 4, !dbg !39, !tbaa !17
  %arrayidx2 = getelementptr inbounds float, ptr %y, i64 %indvars.iv, !dbg !40
  %8 = load float, ptr %arrayidx2, align 4, !dbg !40, !tbaa !17
  %9 = tail call float @llvm.fmuladd.f32(float %a, float %7, float %8), !dbg !41
  store float %9, ptr %arrayidx2, align 4, !dbg !42, !tbaa !17
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !38
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !36
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !37, !llvm.loop !46
}

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare <4 x float> @llvm.fmuladd.v4f32(<4 x float>, <4 x float>, <4 x float>) #2

attributes #0 = { argmemonly nofree nosync nounwind ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn }
attributes #2 = { nocallback nofree nosync nounwind readnone speculatable willreturn }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!9}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 2]}
!1 = !{i32 7, !"Dwarf Version", i32 4}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 7, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 1}
!7 = distinct !DICompileUnit(language: DW_LANG_C99, file: !8, producer: "Homebrew clang version 15.0.7", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly, splitDebugInlining: false, nameTableKind: None, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk", sdk: "MacOSX.sdk")
!8 = !DIFile(filename: "saxpy.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "saxpy", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 3, column: 21, scope: !10)
!14 = !DILocation(line: 3, column: 3, scope: !10)
!15 = !DILocation(line: 3, column: 26, scope: !10)
!16 = !DILocation(line: 4, column: 16, scope: !10)
!17 = !{!18, !18, i64 0}
!18 = !{!"float", !19, i64 0}
!19 = !{!"omnipotent char", !20, i64 0}
!20 = !{!"Simple C/C++ TBAA"}
!21 = !{!22}
!22 = distinct !{!22, !23}
!23 = distinct !{!23, !"LVerDomain"}
!24 = !DILocation(line: 4, column: 23, scope: !10)
!25 = !{!26}
!26 = distinct !{!26, !23}
!27 = !DILocation(line: 4, column: 21, scope: !10)
!28 = !DILocation(line: 4, column: 10, scope: !10)
!29 = distinct !{!29, !14, !30, !31, !32}
!30 = !DILocation(line: 4, column: 26, scope: !10)
!31 = !{!"llvm.loop.mustprogress"}
!32 = !{!"llvm.loop.isvectorized", i32 1}
!33 = !DILocation(line: 5, column: 1, scope: !10)
!34 = distinct !{!34, !14, !30, !31, !32}
!35 = distinct !DISubprogram(name: "saxpy_restrict", scope: !8, file: !8, line: 8, type: !11, scopeLine: 8, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!36 = !DILocation(line: 9, column: 21, scope: !35)
!37 = !DILocation(line: 9, column: 3, scope: !35)
!38 = !DILocation(line: 9, column: 26, scope: !35)
!39 = !DILocation(line: 10, column: 16, scope: !35)
!40 = !DILocation(line: 10, column: 23, scope: !35)
!41 = !DILocation(line: 10, column: 21, scope: !35)
!42 = !DILocation(line: 10, column: 10, scope: !35)
!43 = distinct !{!43, !37, !44, !31, !32}
!44 = !DILocation(line: 10, column: 26, scope: !35)
!45 = !DILocation(line: 11, column: 1, scope: !35)
!46 = distinct !{!46, !37, !44, !31, !47, !32}
!47 = !{!"llvm.loop.unroll.runtime.disable"}
