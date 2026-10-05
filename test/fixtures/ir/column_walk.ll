; ModuleID = 'column_walk.c'
source_filename = "column_walk.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree norecurse nosync nounwind ssp uwtable
define void @scale_columns(ptr noalias nocapture noundef writeonly %out, ptr noalias nocapture noundef readonly %in, i32 noundef %n) local_unnamed_addr #0 !dbg !10 {
entry:
  %cmp24 = icmp sgt i32 %n, 0, !dbg !13
  br i1 %cmp24, label %for.cond1.preheader.lr.ph, label %for.cond.cleanup, !dbg !14

for.cond1.preheader.lr.ph:                        ; preds = %entry
  %0 = zext i32 %n to i64, !dbg !14
  %wide.trip.count32 = zext i32 %n to i64, !dbg !13
  %min.iters.check = icmp ult i32 %n, 2
  %n.vec = and i64 %wide.trip.count32, 4294967294
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count32
  br label %for.body4.preheader, !dbg !14

for.body4.preheader:                              ; preds = %for.cond.cleanup3, %for.cond1.preheader.lr.ph
  %indvars.iv29 = phi i64 [ 0, %for.cond1.preheader.lr.ph ], [ %indvars.iv.next30, %for.cond.cleanup3 ]
  br i1 %min.iters.check, label %for.body4.preheader35, label %vector.body, !dbg !15

vector.body:                                      ; preds = %for.body4.preheader, %vector.body
  %index = phi i64 [ %index.next, %vector.body ], [ 0, %for.body4.preheader ], !dbg !16
  %induction34 = or i64 %index, 1, !dbg !15
  %1 = mul nsw i64 %index, %0, !dbg !17
  %2 = mul nsw i64 %induction34, %0, !dbg !17
  %3 = add nuw nsw i64 %1, %indvars.iv29, !dbg !18
  %4 = add nuw nsw i64 %2, %indvars.iv29, !dbg !18
  %5 = getelementptr inbounds float, ptr %in, i64 %3, !dbg !19
  %6 = getelementptr inbounds float, ptr %in, i64 %4, !dbg !19
  %7 = load float, ptr %5, align 4, !dbg !19, !tbaa !20
  %8 = load float, ptr %6, align 4, !dbg !19, !tbaa !20
  %9 = fmul float %7, 2.000000e+00, !dbg !24
  %10 = fmul float %8, 2.000000e+00, !dbg !24
  %11 = getelementptr inbounds float, ptr %out, i64 %3, !dbg !25
  %12 = getelementptr inbounds float, ptr %out, i64 %4, !dbg !25
  store float %9, ptr %11, align 4, !dbg !26, !tbaa !20
  store float %10, ptr %12, align 4, !dbg !26, !tbaa !20
  %index.next = add nuw i64 %index, 2, !dbg !16
  %13 = icmp eq i64 %index.next, %n.vec, !dbg !16
  br i1 %13, label %middle.block, label %vector.body, !dbg !16, !llvm.loop !27

middle.block:                                     ; preds = %vector.body
  br i1 %cmp.n, label %for.cond.cleanup3, label %for.body4.preheader35, !dbg !15

for.body4.preheader35:                            ; preds = %for.body4.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %for.body4.preheader ], [ %n.vec, %middle.block ]
  br label %for.body4, !dbg !15

for.cond.cleanup:                                 ; preds = %for.cond.cleanup3, %entry
  ret void, !dbg !31

for.cond.cleanup3:                                ; preds = %for.body4, %middle.block
  %indvars.iv.next30 = add nuw nsw i64 %indvars.iv29, 1, !dbg !32
  %exitcond33.not = icmp eq i64 %indvars.iv.next30, %wide.trip.count32, !dbg !13
  br i1 %exitcond33.not, label %for.cond.cleanup, label %for.body4.preheader, !dbg !14, !llvm.loop !33

for.body4:                                        ; preds = %for.body4.preheader35, %for.body4
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body4 ], [ %indvars.iv.ph, %for.body4.preheader35 ]
  %14 = mul nsw i64 %indvars.iv, %0, !dbg !17
  %15 = add nuw nsw i64 %14, %indvars.iv29, !dbg !18
  %arrayidx = getelementptr inbounds float, ptr %in, i64 %15, !dbg !19
  %16 = load float, ptr %arrayidx, align 4, !dbg !19, !tbaa !20
  %mul5 = fmul float %16, 2.000000e+00, !dbg !24
  %arrayidx9 = getelementptr inbounds float, ptr %out, i64 %15, !dbg !25
  store float %mul5, ptr %arrayidx9, align 4, !dbg !26, !tbaa !20
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !16
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count32, !dbg !34
  br i1 %exitcond.not, label %for.cond.cleanup3, label %for.body4, !dbg !15, !llvm.loop !35
}

attributes #0 = { argmemonly nofree norecurse nosync nounwind ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }

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
!8 = !DIFile(filename: "column_walk.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "scale_columns", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 4, column: 21, scope: !10)
!14 = !DILocation(line: 4, column: 3, scope: !10)
!15 = !DILocation(line: 5, column: 5, scope: !10)
!16 = !DILocation(line: 5, column: 28, scope: !10)
!17 = !DILocation(line: 6, column: 36, scope: !10)
!18 = !DILocation(line: 6, column: 40, scope: !10)
!19 = !DILocation(line: 6, column: 31, scope: !10)
!20 = !{!21, !21, i64 0}
!21 = !{!"float", !22, i64 0}
!22 = !{!"omnipotent char", !23, i64 0}
!23 = !{!"Simple C/C++ TBAA"}
!24 = !DILocation(line: 6, column: 29, scope: !10)
!25 = !DILocation(line: 6, column: 7, scope: !10)
!26 = !DILocation(line: 6, column: 22, scope: !10)
!27 = distinct !{!27, !15, !28, !29, !30}
!28 = !DILocation(line: 6, column: 43, scope: !10)
!29 = !{!"llvm.loop.mustprogress"}
!30 = !{!"llvm.loop.isvectorized", i32 1}
!31 = !DILocation(line: 7, column: 1, scope: !10)
!32 = !DILocation(line: 4, column: 26, scope: !10)
!33 = distinct !{!33, !14, !28, !29}
!34 = !DILocation(line: 5, column: 23, scope: !10)
!35 = distinct !{!35, !15, !28, !29, !30}
