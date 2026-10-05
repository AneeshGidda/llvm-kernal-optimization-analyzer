; ModuleID = 'calls.c'
source_filename = "calls.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree nosync nounwind ssp uwtable
define void @apply_sin(ptr noalias nocapture noundef readonly %x, ptr noalias nocapture noundef writeonly %y, i32 noundef %n) local_unnamed_addr #0 !dbg !10 {
entry:
  %cmp6 = icmp sgt i32 %n, 0, !dbg !13
  br i1 %cmp6, label %for.body.preheader, label %for.cond.cleanup, !dbg !14

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !13
  %min.iters.check = icmp eq i32 %n, 1, !dbg !14
  br i1 %min.iters.check, label %for.body.preheader9, label %vector.ph, !dbg !14

vector.ph:                                        ; preds = %for.body.preheader
  %n.vec = and i64 %wide.trip.count, 4294967294, !dbg !14
  br label %vector.body, !dbg !14

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ], !dbg !15
  %0 = getelementptr inbounds float, ptr %x, i64 %index, !dbg !16
  %wide.load = load <2 x float>, ptr %0, align 4, !dbg !16, !tbaa !17
  %1 = tail call <2 x float> @llvm.sin.v2f32(<2 x float> %wide.load), !dbg !21
  %2 = getelementptr inbounds float, ptr %y, i64 %index, !dbg !22
  store <2 x float> %1, ptr %2, align 4, !dbg !23, !tbaa !17
  %index.next = add nuw i64 %index, 2, !dbg !15
  %3 = icmp eq i64 %index.next, %n.vec, !dbg !15
  br i1 %3, label %middle.block, label %vector.body, !dbg !15, !llvm.loop !24

middle.block:                                     ; preds = %vector.body
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count, !dbg !14
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader9, !dbg !14

for.body.preheader9:                              ; preds = %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  br label %for.body, !dbg !14

for.cond.cleanup:                                 ; preds = %for.body, %middle.block, %entry
  ret void, !dbg !28

for.body:                                         ; preds = %for.body.preheader9, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ %indvars.iv.ph, %for.body.preheader9 ]
  %arrayidx = getelementptr inbounds float, ptr %x, i64 %indvars.iv, !dbg !16
  %4 = load float, ptr %arrayidx, align 4, !dbg !16, !tbaa !17
  %5 = tail call float @llvm.sin.f32(float %4), !dbg !21
  %arrayidx2 = getelementptr inbounds float, ptr %y, i64 %indvars.iv, !dbg !22
  store float %5, ptr %arrayidx2, align 4, !dbg !23, !tbaa !17
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !15
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !13
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !14, !llvm.loop !29
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare float @llvm.sin.f32(float) #1

; Function Attrs: nounwind ssp uwtable
define void @apply_transform(ptr noalias nocapture noundef readonly %x, ptr noalias nocapture noundef writeonly %y, i32 noundef %n) local_unnamed_addr #2 !dbg !31 {
entry:
  %cmp6 = icmp sgt i32 %n, 0, !dbg !32
  br i1 %cmp6, label %for.body.preheader, label %for.cond.cleanup, !dbg !33

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !32
  br label %for.body, !dbg !33

for.cond.cleanup:                                 ; preds = %for.body, %entry
  ret void, !dbg !34

for.body:                                         ; preds = %for.body.preheader, %for.body
  %indvars.iv = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next, %for.body ]
  %arrayidx = getelementptr inbounds float, ptr %x, i64 %indvars.iv, !dbg !35
  %0 = load float, ptr %arrayidx, align 4, !dbg !35, !tbaa !17
  %call = tail call float @transform(float noundef %0) #5, !dbg !36
  %arrayidx2 = getelementptr inbounds float, ptr %y, i64 %indvars.iv, !dbg !37
  store float %call, ptr %arrayidx2, align 4, !dbg !38, !tbaa !17
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !39
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !32
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !33, !llvm.loop !40
}

declare !dbg !42 float @transform(float noundef) local_unnamed_addr #3

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare <2 x float> @llvm.sin.v2f32(<2 x float>) #4

attributes #0 = { argmemonly nofree nosync nounwind ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #3 = { "frame-pointer"="non-leaf" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #4 = { nocallback nofree nosync nounwind readnone speculatable willreturn }
attributes #5 = { nounwind }

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
!8 = !DIFile(filename: "calls.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "apply_sin", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 7, column: 21, scope: !10)
!14 = !DILocation(line: 7, column: 3, scope: !10)
!15 = !DILocation(line: 7, column: 26, scope: !10)
!16 = !DILocation(line: 8, column: 17, scope: !10)
!17 = !{!18, !18, i64 0}
!18 = !{!"float", !19, i64 0}
!19 = !{!"omnipotent char", !20, i64 0}
!20 = !{!"Simple C/C++ TBAA"}
!21 = !DILocation(line: 8, column: 12, scope: !10)
!22 = !DILocation(line: 8, column: 5, scope: !10)
!23 = !DILocation(line: 8, column: 10, scope: !10)
!24 = distinct !{!24, !14, !25, !26, !27}
!25 = !DILocation(line: 8, column: 21, scope: !10)
!26 = !{!"llvm.loop.mustprogress"}
!27 = !{!"llvm.loop.isvectorized", i32 1}
!28 = !DILocation(line: 9, column: 1, scope: !10)
!29 = distinct !{!29, !14, !25, !26, !30, !27}
!30 = !{!"llvm.loop.unroll.runtime.disable"}
!31 = distinct !DISubprogram(name: "apply_transform", scope: !8, file: !8, line: 12, type: !11, scopeLine: 12, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!32 = !DILocation(line: 13, column: 21, scope: !31)
!33 = !DILocation(line: 13, column: 3, scope: !31)
!34 = !DILocation(line: 15, column: 1, scope: !31)
!35 = !DILocation(line: 14, column: 22, scope: !31)
!36 = !DILocation(line: 14, column: 12, scope: !31)
!37 = !DILocation(line: 14, column: 5, scope: !31)
!38 = !DILocation(line: 14, column: 10, scope: !31)
!39 = !DILocation(line: 13, column: 26, scope: !31)
!40 = distinct !{!40, !33, !41, !26}
!41 = !DILocation(line: 14, column: 26, scope: !31)
!42 = !DISubprogram(name: "transform", scope: !8, file: !8, line: 3, type: !11, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !12)
