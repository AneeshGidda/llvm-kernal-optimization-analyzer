; ModuleID = 'reduction.c'
source_filename = "reduction.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree norecurse nosync nounwind readonly ssp uwtable
define float @sum_f32(ptr nocapture noundef readonly %a, i32 noundef %n) local_unnamed_addr #0 !dbg !10 {
entry:
  %cmp4 = icmp sgt i32 %n, 0, !dbg !13
  br i1 %cmp4, label %for.body.preheader, label %for.cond.cleanup, !dbg !14

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !13
  %min.iters.check = icmp eq i32 %n, 1, !dbg !14
  br i1 %min.iters.check, label %for.body.preheader9, label %vector.ph, !dbg !14

vector.ph:                                        ; preds = %for.body.preheader
  %n.vec = and i64 %wide.trip.count, 4294967294, !dbg !14
  br label %vector.body, !dbg !14

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ], !dbg !15
  %vec.phi = phi float [ 0.000000e+00, %vector.ph ], [ %5, %vector.body ]
  %induction8 = or i64 %index, 1, !dbg !14
  %0 = getelementptr inbounds float, ptr %a, i64 %index, !dbg !16
  %1 = getelementptr inbounds float, ptr %a, i64 %induction8, !dbg !16
  %2 = load float, ptr %0, align 4, !dbg !16, !tbaa !17
  %3 = load float, ptr %1, align 4, !dbg !16, !tbaa !17
  %4 = fadd float %vec.phi, %2, !dbg !16
  %5 = fadd float %4, %3, !dbg !16
  %index.next = add nuw i64 %index, 2, !dbg !15
  %6 = icmp eq i64 %index.next, %n.vec, !dbg !15
  br i1 %6, label %middle.block, label %vector.body, !dbg !15, !llvm.loop !21

middle.block:                                     ; preds = %vector.body
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count, !dbg !14
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader9, !dbg !14

for.body.preheader9:                              ; preds = %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  %s.05.ph = phi float [ 0.000000e+00, %for.body.preheader ], [ %5, %middle.block ]
  br label %for.body, !dbg !14

for.cond.cleanup:                                 ; preds = %for.body, %middle.block, %entry
  %s.0.lcssa = phi float [ 0.000000e+00, %entry ], [ %5, %middle.block ], [ %add, %for.body ], !dbg !25
  ret float %s.0.lcssa, !dbg !26

for.body:                                         ; preds = %for.body.preheader9, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ %indvars.iv.ph, %for.body.preheader9 ]
  %s.05 = phi float [ %add, %for.body ], [ %s.05.ph, %for.body.preheader9 ]
  %arrayidx = getelementptr inbounds float, ptr %a, i64 %indvars.iv, !dbg !16
  %7 = load float, ptr %arrayidx, align 4, !dbg !16, !tbaa !17
  %add = fadd float %s.05, %7, !dbg !27
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !15
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !13
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !14, !llvm.loop !28
}

; Function Attrs: argmemonly nofree norecurse nosync nounwind readonly ssp uwtable
define i32 @sum_i32(ptr nocapture noundef readonly %a, i32 noundef %n) local_unnamed_addr #0 !dbg !29 {
entry:
  %cmp4 = icmp sgt i32 %n, 0, !dbg !30
  br i1 %cmp4, label %for.body.preheader, label %for.cond.cleanup, !dbg !31

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !30
  %min.iters.check = icmp ult i32 %n, 8, !dbg !31
  br i1 %min.iters.check, label %for.body.preheader10, label %vector.ph, !dbg !31

vector.ph:                                        ; preds = %for.body.preheader
  %n.vec = and i64 %wide.trip.count, 4294967288, !dbg !31
  br label %vector.body, !dbg !31

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ], !dbg !32
  %vec.phi = phi <4 x i32> [ zeroinitializer, %vector.ph ], [ %2, %vector.body ]
  %vec.phi8 = phi <4 x i32> [ zeroinitializer, %vector.ph ], [ %3, %vector.body ]
  %0 = getelementptr inbounds i32, ptr %a, i64 %index, !dbg !33
  %wide.load = load <4 x i32>, ptr %0, align 4, !dbg !33, !tbaa !34
  %1 = getelementptr inbounds i32, ptr %0, i64 4, !dbg !33
  %wide.load9 = load <4 x i32>, ptr %1, align 4, !dbg !33, !tbaa !34
  %2 = add <4 x i32> %wide.load, %vec.phi, !dbg !36
  %3 = add <4 x i32> %wide.load9, %vec.phi8, !dbg !36
  %index.next = add nuw i64 %index, 8, !dbg !32
  %4 = icmp eq i64 %index.next, %n.vec, !dbg !32
  br i1 %4, label %middle.block, label %vector.body, !dbg !32, !llvm.loop !37

middle.block:                                     ; preds = %vector.body
  %bin.rdx = add <4 x i32> %3, %2, !dbg !31
  %5 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %bin.rdx), !dbg !31
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count, !dbg !31
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader10, !dbg !31

for.body.preheader10:                             ; preds = %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  %s.05.ph = phi i32 [ 0, %for.body.preheader ], [ %5, %middle.block ]
  br label %for.body, !dbg !31

for.cond.cleanup:                                 ; preds = %for.body, %middle.block, %entry
  %s.0.lcssa = phi i32 [ 0, %entry ], [ %5, %middle.block ], [ %add, %for.body ], !dbg !39
  ret i32 %s.0.lcssa, !dbg !40

for.body:                                         ; preds = %for.body.preheader10, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ %indvars.iv.ph, %for.body.preheader10 ]
  %s.05 = phi i32 [ %add, %for.body ], [ %s.05.ph, %for.body.preheader10 ]
  %arrayidx = getelementptr inbounds i32, ptr %a, i64 %indvars.iv, !dbg !33
  %6 = load i32, ptr %arrayidx, align 4, !dbg !33, !tbaa !34
  %add = add nsw i32 %6, %s.05, !dbg !36
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !32
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !30
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !31, !llvm.loop !41
}

; Function Attrs: nocallback nofree nosync nounwind readnone willreturn
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>) #1

attributes #0 = { argmemonly nofree norecurse nosync nounwind readonly ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #1 = { nocallback nofree nosync nounwind readnone willreturn }

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
!8 = !DIFile(filename: "reduction.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "sum_f32", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 4, column: 21, scope: !10)
!14 = !DILocation(line: 4, column: 3, scope: !10)
!15 = !DILocation(line: 4, column: 26, scope: !10)
!16 = !DILocation(line: 5, column: 10, scope: !10)
!17 = !{!18, !18, i64 0}
!18 = !{!"float", !19, i64 0}
!19 = !{!"omnipotent char", !20, i64 0}
!20 = !{!"Simple C/C++ TBAA"}
!21 = distinct !{!21, !14, !22, !23, !24}
!22 = !DILocation(line: 5, column: 13, scope: !10)
!23 = !{!"llvm.loop.mustprogress"}
!24 = !{!"llvm.loop.isvectorized", i32 1}
!25 = !DILocation(line: 0, scope: !10)
!26 = !DILocation(line: 6, column: 3, scope: !10)
!27 = !DILocation(line: 5, column: 7, scope: !10)
!28 = distinct !{!28, !14, !22, !23, !24}
!29 = distinct !DISubprogram(name: "sum_i32", scope: !8, file: !8, line: 10, type: !11, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!30 = !DILocation(line: 12, column: 21, scope: !29)
!31 = !DILocation(line: 12, column: 3, scope: !29)
!32 = !DILocation(line: 12, column: 26, scope: !29)
!33 = !DILocation(line: 13, column: 10, scope: !29)
!34 = !{!35, !35, i64 0}
!35 = !{!"int", !19, i64 0}
!36 = !DILocation(line: 13, column: 7, scope: !29)
!37 = distinct !{!37, !31, !38, !23, !24}
!38 = !DILocation(line: 13, column: 13, scope: !29)
!39 = !DILocation(line: 0, scope: !29)
!40 = !DILocation(line: 14, column: 3, scope: !29)
!41 = distinct !{!41, !31, !38, !23, !42, !24}
!42 = !{!"llvm.loop.unroll.runtime.disable"}
