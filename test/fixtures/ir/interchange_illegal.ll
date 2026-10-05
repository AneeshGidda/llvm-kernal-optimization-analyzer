; ModuleID = 'interchange_illegal.c'
source_filename = "interchange_illegal.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree norecurse nosync nounwind ssp uwtable
define void @skew(ptr noalias nocapture noundef %A) local_unnamed_addr #0 !dbg !10 {
entry:
  br label %for.cond1.preheader, !dbg !13

for.cond1.preheader:                              ; preds = %entry, %for.cond.cleanup3
  %indvars.iv25 = phi i64 [ 1, %entry ], [ %indvars.iv.next26, %for.cond.cleanup3 ]
  %0 = add nsw i64 %indvars.iv25, -1
  br label %for.body4, !dbg !14

for.cond.cleanup:                                 ; preds = %for.cond.cleanup3
  ret void, !dbg !15

for.cond.cleanup3:                                ; preds = %for.body4
  %indvars.iv.next26 = add nuw nsw i64 %indvars.iv25, 1, !dbg !16
  %exitcond29.not = icmp eq i64 %indvars.iv.next26, 255, !dbg !17
  br i1 %exitcond29.not, label %for.cond.cleanup, label %for.cond1.preheader, !dbg !13, !llvm.loop !18

for.body4:                                        ; preds = %for.cond1.preheader, %for.body4
  %indvars.iv = phi i64 [ 1, %for.cond1.preheader ], [ %indvars.iv.next, %for.body4 ]
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !21
  %arrayidx6 = getelementptr inbounds [256 x float], ptr %A, i64 %indvars.iv.next, i64 %0, !dbg !22
  %1 = load float, ptr %arrayidx6, align 4, !dbg !22, !tbaa !23
  %add7 = fadd float %1, 1.000000e+00, !dbg !27
  %arrayidx11 = getelementptr inbounds [256 x float], ptr %A, i64 %indvars.iv, i64 %indvars.iv25, !dbg !28
  store float %add7, ptr %arrayidx11, align 4, !dbg !29, !tbaa !23
  %exitcond.not = icmp eq i64 %indvars.iv.next, 255, !dbg !30
  br i1 %exitcond.not, label %for.cond.cleanup3, label %for.body4, !dbg !14, !llvm.loop !31
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
!8 = !DIFile(filename: "interchange_illegal.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "skew", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 6, column: 3, scope: !10)
!14 = !DILocation(line: 8, column: 5, scope: !10)
!15 = !DILocation(line: 10, column: 1, scope: !10)
!16 = !DILocation(line: 6, column: 30, scope: !10)
!17 = !DILocation(line: 6, column: 21, scope: !10)
!18 = distinct !{!18, !13, !19, !20}
!19 = !DILocation(line: 9, column: 35, scope: !10)
!20 = !{!"llvm.loop.mustprogress"}
!21 = !DILocation(line: 9, column: 21, scope: !10)
!22 = !DILocation(line: 9, column: 17, scope: !10)
!23 = !{!24, !24, i64 0}
!24 = !{!"float", !25, i64 0}
!25 = !{!"omnipotent char", !26, i64 0}
!26 = !{!"Simple C/C++ TBAA"}
!27 = !DILocation(line: 9, column: 33, scope: !10)
!28 = !DILocation(line: 9, column: 7, scope: !10)
!29 = !DILocation(line: 9, column: 15, scope: !10)
!30 = !DILocation(line: 8, column: 23, scope: !10)
!31 = distinct !{!31, !14, !19, !20, !32, !33, !34}
!32 = !{!"llvm.loop.unroll.disable"}
!33 = !{!"llvm.loop.vectorize.width", i32 1}
!34 = !{!"llvm.loop.interleave.count", i32 1}
