; ModuleID = 'matmul.c'
source_filename = "matmul.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree nosync nounwind ssp uwtable
define void @matmul(ptr nocapture noundef readonly %A, ptr nocapture noundef readonly %B, ptr nocapture noundef writeonly %C, i32 noundef %n) local_unnamed_addr #0 !dbg !10 {
entry:
  %cmp44 = icmp sgt i32 %n, 0, !dbg !13
  br i1 %cmp44, label %for.cond1.preheader.lr.ph, label %for.cond.cleanup, !dbg !14

for.cond1.preheader.lr.ph:                        ; preds = %entry
  %0 = zext i32 %n to i64, !dbg !14
  %wide.trip.count61 = zext i32 %n to i64, !dbg !13
  br label %for.cond5.preheader.lr.ph, !dbg !14

for.cond5.preheader.lr.ph:                        ; preds = %for.cond.cleanup3, %for.cond1.preheader.lr.ph
  %indvars.iv56 = phi i64 [ 0, %for.cond1.preheader.lr.ph ], [ %indvars.iv.next57, %for.cond.cleanup3 ]
  %1 = mul nsw i64 %indvars.iv56, %0
  br label %for.body8.preheader, !dbg !15

for.cond.cleanup:                                 ; preds = %for.cond.cleanup3, %entry
  ret void, !dbg !16

for.body8.preheader:                              ; preds = %for.cond.cleanup7, %for.cond5.preheader.lr.ph
  %indvars.iv50 = phi i64 [ 0, %for.cond5.preheader.lr.ph ], [ %indvars.iv.next51, %for.cond.cleanup7 ]
  br label %for.body8, !dbg !17

for.cond.cleanup3:                                ; preds = %for.cond.cleanup7
  %indvars.iv.next57 = add nuw nsw i64 %indvars.iv56, 1, !dbg !18
  %exitcond62.not = icmp eq i64 %indvars.iv.next57, %wide.trip.count61, !dbg !13
  br i1 %exitcond62.not, label %for.cond.cleanup, label %for.cond5.preheader.lr.ph, !dbg !14, !llvm.loop !19

for.cond.cleanup7:                                ; preds = %for.body8
  %2 = add nuw nsw i64 %indvars.iv50, %1, !dbg !22
  %arrayidx17 = getelementptr inbounds float, ptr %C, i64 %2, !dbg !23
  store float %8, ptr %arrayidx17, align 4, !dbg !24, !tbaa !25
  %indvars.iv.next51 = add nuw nsw i64 %indvars.iv50, 1, !dbg !29
  %exitcond55.not = icmp eq i64 %indvars.iv.next51, %wide.trip.count61, !dbg !30
  br i1 %exitcond55.not, label %for.cond.cleanup3, label %for.body8.preheader, !dbg !15, !llvm.loop !31

for.body8:                                        ; preds = %for.body8.preheader, %for.body8
  %indvars.iv = phi i64 [ 0, %for.body8.preheader ], [ %indvars.iv.next, %for.body8 ]
  %sum.040 = phi float [ 0.000000e+00, %for.body8.preheader ], [ %8, %for.body8 ]
  %3 = add nuw nsw i64 %indvars.iv, %1, !dbg !32
  %arrayidx = getelementptr inbounds float, ptr %A, i64 %3, !dbg !33
  %4 = load float, ptr %arrayidx, align 4, !dbg !33, !tbaa !25
  %5 = mul nsw i64 %indvars.iv, %0, !dbg !34
  %6 = add nuw nsw i64 %5, %indvars.iv50, !dbg !35
  %arrayidx12 = getelementptr inbounds float, ptr %B, i64 %6, !dbg !36
  %7 = load float, ptr %arrayidx12, align 4, !dbg !36, !tbaa !25
  %8 = tail call float @llvm.fmuladd.f32(float %4, float %7, float %sum.040), !dbg !37
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !38
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count61, !dbg !39
  br i1 %exitcond.not, label %for.cond.cleanup7, label %for.body8, !dbg !17, !llvm.loop !40
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare float @llvm.fmuladd.f32(float, float, float) #1

attributes #0 = { argmemonly nofree nosync nounwind ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn }

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
!8 = !DIFile(filename: "matmul.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "matmul", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 5, column: 21, scope: !10)
!14 = !DILocation(line: 5, column: 3, scope: !10)
!15 = !DILocation(line: 6, column: 5, scope: !10)
!16 = !DILocation(line: 12, column: 1, scope: !10)
!17 = !DILocation(line: 8, column: 7, scope: !10)
!18 = !DILocation(line: 5, column: 26, scope: !10)
!19 = distinct !{!19, !14, !20, !21}
!20 = !DILocation(line: 11, column: 5, scope: !10)
!21 = !{!"llvm.loop.mustprogress"}
!22 = !DILocation(line: 10, column: 15, scope: !10)
!23 = !DILocation(line: 10, column: 7, scope: !10)
!24 = !DILocation(line: 10, column: 20, scope: !10)
!25 = !{!26, !26, i64 0}
!26 = !{!"float", !27, i64 0}
!27 = !{!"omnipotent char", !28, i64 0}
!28 = !{!"Simple C/C++ TBAA"}
!29 = !DILocation(line: 6, column: 28, scope: !10)
!30 = !DILocation(line: 6, column: 23, scope: !10)
!31 = distinct !{!31, !15, !20, !21}
!32 = !DILocation(line: 9, column: 24, scope: !10)
!33 = !DILocation(line: 9, column: 16, scope: !10)
!34 = !DILocation(line: 9, column: 35, scope: !10)
!35 = !DILocation(line: 9, column: 39, scope: !10)
!36 = !DILocation(line: 9, column: 31, scope: !10)
!37 = !DILocation(line: 9, column: 13, scope: !10)
!38 = !DILocation(line: 8, column: 30, scope: !10)
!39 = !DILocation(line: 8, column: 25, scope: !10)
!40 = distinct !{!40, !17, !41, !21}
!41 = !DILocation(line: 9, column: 42, scope: !10)
