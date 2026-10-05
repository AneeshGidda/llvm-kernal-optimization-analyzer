; ModuleID = 'recurrences.c'
source_filename = "recurrences.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree nosync nounwind ssp uwtable
define void @shift_add(ptr nocapture noundef %a, i32 noundef %n) local_unnamed_addr #0 !dbg !10 {
entry:
  %cmp7 = icmp sgt i32 %n, 0, !dbg !13
  br i1 %cmp7, label %for.body.preheader, label %for.cond.cleanup, !dbg !14

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !13
  %.pre = load float, ptr %a, align 4, !dbg !15, !tbaa !16
  br label %for.body, !dbg !14

for.cond.cleanup:                                 ; preds = %for.body, %entry
  ret void, !dbg !20

for.body:                                         ; preds = %for.body.preheader, %for.body
  %0 = phi float [ %.pre, %for.body.preheader ], [ %1, %for.body ], !dbg !15
  %indvars.iv = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next, %for.body ]
  %1 = tail call float @llvm.fmuladd.f32(float %0, float 5.000000e-01, float 1.000000e+00), !dbg !21
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !22
  %arrayidx2 = getelementptr inbounds float, ptr %a, i64 %indvars.iv.next, !dbg !23
  store float %1, ptr %arrayidx2, align 4, !dbg !24, !tbaa !16
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !13
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !14, !llvm.loop !25
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare float @llvm.fmuladd.f32(float, float, float) #1

; Function Attrs: argmemonly nofree norecurse nosync nounwind readonly ssp uwtable
define i32 @argmax(ptr nocapture noundef readonly %a, i32 noundef %n) local_unnamed_addr #2 !dbg !28 {
entry:
  %cmp11 = icmp sgt i32 %n, 1, !dbg !29
  br i1 %cmp11, label %for.body.preheader, label %for.cond.cleanup, !dbg !30

for.body.preheader:                               ; preds = %entry
  %0 = load float, ptr %a, align 4, !dbg !31, !tbaa !16
  %wide.trip.count = zext i32 %n to i64, !dbg !29
  br label %for.body, !dbg !30

for.cond.cleanup:                                 ; preds = %for.body, %entry
  %best.0.lcssa = phi i32 [ 0, %entry ], [ %best.1, %for.body ], !dbg !32
  ret i32 %best.0.lcssa, !dbg !33

for.body:                                         ; preds = %for.body.preheader, %for.body
  %indvars.iv = phi i64 [ 1, %for.body.preheader ], [ %indvars.iv.next, %for.body ]
  %bestv.013 = phi float [ %0, %for.body.preheader ], [ %bestv.1, %for.body ]
  %best.012 = phi i32 [ 0, %for.body.preheader ], [ %best.1, %for.body ]
  %arrayidx1 = getelementptr inbounds float, ptr %a, i64 %indvars.iv, !dbg !34
  %1 = load float, ptr %arrayidx1, align 4, !dbg !34, !tbaa !16
  %cmp2 = fcmp ogt float %1, %bestv.013, !dbg !35
  %2 = trunc i64 %indvars.iv to i32, !dbg !34
  %best.1 = select i1 %cmp2, i32 %2, i32 %best.012, !dbg !34
  %bestv.1 = select i1 %cmp2, float %1, float %bestv.013, !dbg !34
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !36
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !29
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !30, !llvm.loop !37
}

attributes #0 = { argmemonly nofree nosync nounwind ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn }
attributes #2 = { argmemonly nofree norecurse nosync nounwind readonly ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }

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
!8 = !DIFile(filename: "recurrences.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "shift_add", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 3, column: 21, scope: !10)
!14 = !DILocation(line: 3, column: 3, scope: !10)
!15 = !DILocation(line: 4, column: 16, scope: !10)
!16 = !{!17, !17, i64 0}
!17 = !{!"float", !18, i64 0}
!18 = !{!"omnipotent char", !19, i64 0}
!19 = !{!"Simple C/C++ TBAA"}
!20 = !DILocation(line: 5, column: 1, scope: !10)
!21 = !DILocation(line: 4, column: 28, scope: !10)
!22 = !DILocation(line: 4, column: 9, scope: !10)
!23 = !DILocation(line: 4, column: 5, scope: !10)
!24 = !DILocation(line: 4, column: 14, scope: !10)
!25 = distinct !{!25, !14, !26, !27}
!26 = !DILocation(line: 4, column: 30, scope: !10)
!27 = !{!"llvm.loop.mustprogress"}
!28 = distinct !DISubprogram(name: "argmax", scope: !8, file: !8, line: 8, type: !11, scopeLine: 8, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!29 = !DILocation(line: 11, column: 21, scope: !28)
!30 = !DILocation(line: 11, column: 3, scope: !28)
!31 = !DILocation(line: 10, column: 17, scope: !28)
!32 = !DILocation(line: 0, scope: !28)
!33 = !DILocation(line: 16, column: 3, scope: !28)
!34 = !DILocation(line: 12, column: 9, scope: !28)
!35 = !DILocation(line: 12, column: 14, scope: !28)
!36 = !DILocation(line: 11, column: 26, scope: !28)
!37 = distinct !{!37, !30, !38, !27}
!38 = !DILocation(line: 15, column: 5, scope: !28)
