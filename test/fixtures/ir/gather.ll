; ModuleID = 'gather.c'
source_filename = "gather.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree norecurse nosync nounwind ssp uwtable
define void @gather(ptr nocapture noundef readonly %x, ptr nocapture noundef readonly %idx, ptr nocapture noundef writeonly %y, i32 noundef %n) local_unnamed_addr #0 !dbg !10 {
entry:
  %cmp8 = icmp sgt i32 %n, 0, !dbg !13
  br i1 %cmp8, label %for.body.preheader, label %for.cond.cleanup, !dbg !14

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !13
  br label %for.body, !dbg !14

for.cond.cleanup:                                 ; preds = %for.body, %entry
  ret void, !dbg !15

for.body:                                         ; preds = %for.body.preheader, %for.body
  %indvars.iv = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next, %for.body ]
  %arrayidx = getelementptr inbounds i32, ptr %idx, i64 %indvars.iv, !dbg !16
  %0 = load i32, ptr %arrayidx, align 4, !dbg !16, !tbaa !17
  %idxprom1 = sext i32 %0 to i64, !dbg !21
  %arrayidx2 = getelementptr inbounds float, ptr %x, i64 %idxprom1, !dbg !21
  %1 = load float, ptr %arrayidx2, align 4, !dbg !21, !tbaa !22
  %arrayidx4 = getelementptr inbounds float, ptr %y, i64 %indvars.iv, !dbg !24
  store float %1, ptr %arrayidx4, align 4, !dbg !25, !tbaa !22
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !26
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !13
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !14, !llvm.loop !27
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
!8 = !DIFile(filename: "gather.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "gather", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 3, column: 21, scope: !10)
!14 = !DILocation(line: 3, column: 3, scope: !10)
!15 = !DILocation(line: 5, column: 1, scope: !10)
!16 = !DILocation(line: 4, column: 14, scope: !10)
!17 = !{!18, !18, i64 0}
!18 = !{!"int", !19, i64 0}
!19 = !{!"omnipotent char", !20, i64 0}
!20 = !{!"Simple C/C++ TBAA"}
!21 = !DILocation(line: 4, column: 12, scope: !10)
!22 = !{!23, !23, i64 0}
!23 = !{!"float", !19, i64 0}
!24 = !DILocation(line: 4, column: 5, scope: !10)
!25 = !DILocation(line: 4, column: 10, scope: !10)
!26 = !DILocation(line: 3, column: 26, scope: !10)
!27 = distinct !{!27, !14, !28, !29}
!28 = !DILocation(line: 4, column: 20, scope: !10)
!29 = !{!"llvm.loop.mustprogress"}
