; ModuleID = 'fixed_trip.c'
source_filename = "fixed_trip.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree norecurse nosync nounwind readonly ssp uwtable
define float @sum1003(ptr nocapture noundef readonly %a) local_unnamed_addr #0 !dbg !10 {
entry:
  br label %vector.body, !dbg !13

vector.body:                                      ; preds = %vector.body, %entry
  %index = phi i64 [ 0, %entry ], [ %index.next, %vector.body ], !dbg !14
  %vec.phi = phi float [ 0.000000e+00, %entry ], [ %5, %vector.body ]
  %induction7 = or i64 %index, 1, !dbg !13
  %0 = getelementptr inbounds float, ptr %a, i64 %index, !dbg !15
  %1 = getelementptr inbounds float, ptr %a, i64 %induction7, !dbg !15
  %2 = load float, ptr %0, align 4, !dbg !15, !tbaa !16
  %3 = load float, ptr %1, align 4, !dbg !15, !tbaa !16
  %4 = fadd float %vec.phi, %2, !dbg !15
  %5 = fadd float %4, %3, !dbg !15
  %index.next = add nuw i64 %index, 2, !dbg !14
  %6 = icmp eq i64 %index.next, 1002, !dbg !14
  br i1 %6, label %for.body, label %vector.body, !dbg !14, !llvm.loop !20

for.body:                                         ; preds = %vector.body
  %arrayidx = getelementptr inbounds float, ptr %a, i64 1002, !dbg !15
  %7 = load float, ptr %arrayidx, align 4, !dbg !15, !tbaa !16
  %add = fadd float %5, %7, !dbg !24
  ret float %add, !dbg !25
}

attributes #0 = { argmemonly nofree norecurse nosync nounwind readonly ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }

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
!8 = !DIFile(filename: "fixed_trip.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "sum1003", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 5, column: 3, scope: !10)
!14 = !DILocation(line: 5, column: 29, scope: !10)
!15 = !DILocation(line: 6, column: 10, scope: !10)
!16 = !{!17, !17, i64 0}
!17 = !{!"float", !18, i64 0}
!18 = !{!"omnipotent char", !19, i64 0}
!19 = !{!"Simple C/C++ TBAA"}
!20 = distinct !{!20, !13, !21, !22, !23}
!21 = !DILocation(line: 6, column: 13, scope: !10)
!22 = !{!"llvm.loop.mustprogress"}
!23 = !{!"llvm.loop.isvectorized", i32 1}
!24 = !DILocation(line: 6, column: 7, scope: !10)
!25 = !DILocation(line: 7, column: 3, scope: !10)
