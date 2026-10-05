; ModuleID = 'search.c'
source_filename = "search.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree norecurse nosync nounwind readonly ssp uwtable
define i32 @find_first(ptr nocapture noundef readonly %a, i32 noundef %n, i32 noundef %key) local_unnamed_addr #0 !dbg !10 {
entry:
  %cmp5 = icmp sgt i32 %n, 0, !dbg !13
  br i1 %cmp5, label %for.body.preheader, label %cleanup, !dbg !14

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !13
  br label %for.body, !dbg !14

for.body:                                         ; preds = %for.body.preheader, %for.inc
  %indvars.iv = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next, %for.inc ]
  %arrayidx = getelementptr inbounds i32, ptr %a, i64 %indvars.iv, !dbg !15
  %0 = load i32, ptr %arrayidx, align 4, !dbg !15, !tbaa !16
  %cmp1 = icmp eq i32 %0, %key, !dbg !20
  br i1 %cmp1, label %cleanup.loopexit.split.loop.exit, label %for.inc, !dbg !15

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !21
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !13
  br i1 %exitcond.not, label %cleanup, label %for.body, !dbg !14, !llvm.loop !22

cleanup.loopexit.split.loop.exit:                 ; preds = %for.body
  %1 = trunc i64 %indvars.iv to i32, !dbg !15
  br label %cleanup, !dbg !25

cleanup:                                          ; preds = %for.inc, %cleanup.loopexit.split.loop.exit, %entry
  %spec.select = phi i32 [ -1, %entry ], [ %1, %cleanup.loopexit.split.loop.exit ], [ -1, %for.inc ]
  ret i32 %spec.select, !dbg !25
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
!8 = !DIFile(filename: "search.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "find_first", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 3, column: 21, scope: !10)
!14 = !DILocation(line: 3, column: 3, scope: !10)
!15 = !DILocation(line: 4, column: 9, scope: !10)
!16 = !{!17, !17, i64 0}
!17 = !{!"int", !18, i64 0}
!18 = !{!"omnipotent char", !19, i64 0}
!19 = !{!"Simple C/C++ TBAA"}
!20 = !DILocation(line: 4, column: 14, scope: !10)
!21 = !DILocation(line: 3, column: 26, scope: !10)
!22 = distinct !{!22, !14, !23, !24}
!23 = !DILocation(line: 5, column: 14, scope: !10)
!24 = !{!"llvm.loop.mustprogress"}
!25 = !DILocation(line: 7, column: 1, scope: !10)
