; ModuleID = 'interleave_only.c'
source_filename = "interleave_only.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree norecurse nosync nounwind ssp uwtable
define void @colwalk_const(ptr noalias nocapture noundef writeonly %out, ptr noalias nocapture noundef readonly %in) local_unnamed_addr #0 !dbg !10 {
entry:
  br label %vector.ph, !dbg !13

vector.ph:                                        ; preds = %for.cond.cleanup3, %entry
  %indvars.iv23 = phi i64 [ 0, %entry ], [ %indvars.iv.next24, %for.cond.cleanup3 ]
  br label %vector.body, !dbg !14

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ], !dbg !15
  %induction27 = or i64 %index, 1, !dbg !14
  %0 = getelementptr inbounds [256 x float], ptr %in, i64 %index, i64 %indvars.iv23, !dbg !16
  %1 = getelementptr inbounds [256 x float], ptr %in, i64 %induction27, i64 %indvars.iv23, !dbg !16
  %2 = load float, ptr %0, align 4, !dbg !16, !tbaa !17
  %3 = load float, ptr %1, align 4, !dbg !16, !tbaa !17
  %4 = fmul float %2, 2.000000e+00, !dbg !21
  %5 = fmul float %3, 2.000000e+00, !dbg !21
  %6 = getelementptr inbounds [256 x float], ptr %out, i64 %index, i64 %indvars.iv23, !dbg !22
  %7 = getelementptr inbounds [256 x float], ptr %out, i64 %induction27, i64 %indvars.iv23, !dbg !22
  store float %4, ptr %6, align 4, !dbg !23, !tbaa !17
  store float %5, ptr %7, align 4, !dbg !23, !tbaa !17
  %index.next = add nuw i64 %index, 2, !dbg !15
  %8 = icmp eq i64 %index.next, 256, !dbg !15
  br i1 %8, label %for.cond.cleanup3, label %vector.body, !dbg !15, !llvm.loop !24

for.cond.cleanup:                                 ; preds = %for.cond.cleanup3
  ret void, !dbg !28

for.cond.cleanup3:                                ; preds = %vector.body
  %indvars.iv.next24 = add nuw nsw i64 %indvars.iv23, 1, !dbg !29
  %exitcond26.not = icmp eq i64 %indvars.iv.next24, 256, !dbg !30
  br i1 %exitcond26.not, label %for.cond.cleanup, label %vector.ph, !dbg !13, !llvm.loop !31
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
!8 = !DIFile(filename: "interleave_only.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "colwalk_const", scope: !8, file: !8, line: 4, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 6, column: 3, scope: !10)
!14 = !DILocation(line: 7, column: 5, scope: !10)
!15 = !DILocation(line: 7, column: 30, scope: !10)
!16 = !DILocation(line: 8, column: 26, scope: !10)
!17 = !{!18, !18, i64 0}
!18 = !{!"float", !19, i64 0}
!19 = !{!"omnipotent char", !20, i64 0}
!20 = !{!"Simple C/C++ TBAA"}
!21 = !DILocation(line: 8, column: 24, scope: !10)
!22 = !DILocation(line: 8, column: 7, scope: !10)
!23 = !DILocation(line: 8, column: 17, scope: !10)
!24 = distinct !{!24, !14, !25, !26, !27}
!25 = !DILocation(line: 8, column: 33, scope: !10)
!26 = !{!"llvm.loop.mustprogress"}
!27 = !{!"llvm.loop.isvectorized", i32 1}
!28 = !DILocation(line: 9, column: 1, scope: !10)
!29 = !DILocation(line: 6, column: 28, scope: !10)
!30 = !DILocation(line: 6, column: 21, scope: !10)
!31 = distinct !{!31, !13, !25, !26}
