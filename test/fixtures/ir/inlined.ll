; ModuleID = 'inlined.c'
source_filename = "inlined.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: nounwind ssp uwtable
define void @two_calls(ptr noalias nocapture noundef writeonly %a, ptr noalias nocapture noundef writeonly %b, ptr noalias nocapture noundef readonly %x, i32 noundef %n) local_unnamed_addr #0 !dbg !10 {
entry:
  tail call void @llvm.experimental.noalias.scope.decl(metadata !13), !dbg !16
  tail call void @llvm.experimental.noalias.scope.decl(metadata !17), !dbg !16
  %cmp10.i = icmp sgt i32 %n, 0, !dbg !19
  br i1 %cmp10.i, label %for.body.lr.ph.i, label %apply.exit12, !dbg !22

for.body.lr.ph.i:                                 ; preds = %entry
  %wide.trip.count.i = zext i32 %n to i64, !dbg !19
  %min.iters.check = icmp ult i32 %n, 8, !dbg !22
  br i1 %min.iters.check, label %for.body.i.preheader, label %vector.ph, !dbg !22

vector.ph:                                        ; preds = %for.body.lr.ph.i
  %n.vec = and i64 %wide.trip.count.i, 4294967288, !dbg !22
  br label %vector.body, !dbg !22

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ], !dbg !23
  %0 = getelementptr inbounds float, ptr %x, i64 %index, !dbg !24
  %wide.load = load <4 x float>, ptr %0, align 4, !dbg !24, !tbaa !25, !alias.scope !17, !noalias !13
  %1 = getelementptr inbounds float, ptr %0, i64 4, !dbg !24
  %wide.load13 = load <4 x float>, ptr %1, align 4, !dbg !24, !tbaa !25, !alias.scope !17, !noalias !13
  %2 = fmul <4 x float> %wide.load, <float 2.000000e+00, float 2.000000e+00, float 2.000000e+00, float 2.000000e+00>, !dbg !29
  %3 = fmul <4 x float> %wide.load13, <float 2.000000e+00, float 2.000000e+00, float 2.000000e+00, float 2.000000e+00>, !dbg !29
  %4 = getelementptr inbounds float, ptr %a, i64 %index, !dbg !30
  store <4 x float> %2, ptr %4, align 4, !dbg !31, !tbaa !25, !alias.scope !13, !noalias !17
  %5 = getelementptr inbounds float, ptr %4, i64 4, !dbg !31
  store <4 x float> %3, ptr %5, align 4, !dbg !31, !tbaa !25, !alias.scope !13, !noalias !17
  %index.next = add nuw i64 %index, 8, !dbg !23
  %6 = icmp eq i64 %index.next, %n.vec, !dbg !23
  br i1 %6, label %middle.block, label %vector.body, !dbg !23, !llvm.loop !32

middle.block:                                     ; preds = %vector.body
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count.i, !dbg !22
  br i1 %cmp.n, label %for.body.lr.ph.i5, label %for.body.i.preheader, !dbg !22

for.body.i.preheader:                             ; preds = %for.body.lr.ph.i, %middle.block
  %indvars.iv.i.ph = phi i64 [ 0, %for.body.lr.ph.i ], [ %n.vec, %middle.block ]
  br label %for.body.i, !dbg !22

for.body.i:                                       ; preds = %for.body.i.preheader, %for.body.i
  %indvars.iv.i = phi i64 [ %indvars.iv.next.i, %for.body.i ], [ %indvars.iv.i.ph, %for.body.i.preheader ]
  %arrayidx2.i = getelementptr inbounds float, ptr %x, i64 %indvars.iv.i, !dbg !24
  %7 = load float, ptr %arrayidx2.i, align 4, !dbg !24, !tbaa !25, !alias.scope !17, !noalias !13
  %mul.i = fmul float %7, 2.000000e+00, !dbg !29
  %arrayidx4.i = getelementptr inbounds float, ptr %a, i64 %indvars.iv.i, !dbg !30
  store float %mul.i, ptr %arrayidx4.i, align 4, !dbg !31, !tbaa !25, !alias.scope !13, !noalias !17
  %indvars.iv.next.i = add nuw nsw i64 %indvars.iv.i, 1, !dbg !23
  %exitcond.not.i = icmp eq i64 %indvars.iv.next.i, %wide.trip.count.i, !dbg !19
  br i1 %exitcond.not.i, label %for.body.lr.ph.i5, label %for.body.i, !dbg !22, !llvm.loop !36

for.body.lr.ph.i5:                                ; preds = %for.body.i, %middle.block
  tail call void @llvm.experimental.noalias.scope.decl(metadata !38), !dbg !41
  tail call void @llvm.experimental.noalias.scope.decl(metadata !42), !dbg !41
  br label %for.body.i8, !dbg !44

for.body.i8:                                      ; preds = %for.body.i8, %for.body.lr.ph.i5
  %indvars.iv.i6 = phi i64 [ 0, %for.body.lr.ph.i5 ], [ %indvars.iv.next.i10, %for.body.i8 ]
  %arrayidx2.i7 = getelementptr inbounds float, ptr %x, i64 %indvars.iv.i6, !dbg !46
  %8 = load float, ptr %arrayidx2.i7, align 4, !dbg !46, !tbaa !25, !alias.scope !42, !noalias !38
  %call.i = tail call float @transform(float noundef %8) #3, !dbg !47, !noalias !48
  %arrayidx4.i9 = getelementptr inbounds float, ptr %b, i64 %indvars.iv.i6, !dbg !49
  store float %call.i, ptr %arrayidx4.i9, align 4, !dbg !50, !tbaa !25, !alias.scope !38, !noalias !42
  %indvars.iv.next.i10 = add nuw nsw i64 %indvars.iv.i6, 1, !dbg !51
  %exitcond.not.i11 = icmp eq i64 %indvars.iv.next.i10, %wide.trip.count.i, !dbg !52
  br i1 %exitcond.not.i11, label %apply.exit12, label %for.body.i8, !dbg !44, !llvm.loop !53

apply.exit12:                                     ; preds = %for.body.i8, %entry
  ret void, !dbg !55
}

declare !dbg !56 float @transform(float noundef) local_unnamed_addr #1

; Function Attrs: inaccessiblememonly nocallback nofree nosync nounwind willreturn
declare void @llvm.experimental.noalias.scope.decl(metadata) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #1 = { "frame-pointer"="non-leaf" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #2 = { inaccessiblememonly nocallback nofree nosync nounwind willreturn }
attributes #3 = { nounwind }

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
!8 = !DIFile(filename: "inlined.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "two_calls", scope: !8, file: !8, line: 10, type: !11, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !{!14}
!14 = distinct !{!14, !15, !"apply: %y"}
!15 = distinct !{!15, !"apply"}
!16 = !DILocation(line: 12, column: 3, scope: !10)
!17 = !{!18}
!18 = distinct !{!18, !15, !"apply: %x"}
!19 = !DILocation(line: 6, column: 21, scope: !20, inlinedAt: !21)
!20 = distinct !DISubprogram(name: "apply", scope: !8, file: !8, line: 4, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!21 = distinct !DILocation(line: 12, column: 3, scope: !10)
!22 = !DILocation(line: 6, column: 3, scope: !20, inlinedAt: !21)
!23 = !DILocation(line: 6, column: 26, scope: !20, inlinedAt: !21)
!24 = !DILocation(line: 0, scope: !20, inlinedAt: !21)
!25 = !{!26, !26, i64 0}
!26 = !{!"float", !27, i64 0}
!27 = !{!"omnipotent char", !28, i64 0}
!28 = !{!"Simple C/C++ TBAA"}
!29 = !DILocation(line: 7, column: 44, scope: !20, inlinedAt: !21)
!30 = !DILocation(line: 7, column: 5, scope: !20, inlinedAt: !21)
!31 = !DILocation(line: 7, column: 10, scope: !20, inlinedAt: !21)
!32 = distinct !{!32, !22, !33, !34, !35}
!33 = !DILocation(line: 7, column: 49, scope: !20, inlinedAt: !21)
!34 = !{!"llvm.loop.mustprogress"}
!35 = !{!"llvm.loop.isvectorized", i32 1}
!36 = distinct !{!36, !22, !33, !34, !37, !35}
!37 = !{!"llvm.loop.unroll.runtime.disable"}
!38 = !{!39}
!39 = distinct !{!39, !40, !"apply: %y"}
!40 = distinct !{!40, !"apply"}
!41 = !DILocation(line: 13, column: 3, scope: !10)
!42 = !{!43}
!43 = distinct !{!43, !40, !"apply: %x"}
!44 = !DILocation(line: 6, column: 3, scope: !20, inlinedAt: !45)
!45 = distinct !DILocation(line: 13, column: 3, scope: !10)
!46 = !DILocation(line: 0, scope: !20, inlinedAt: !45)
!47 = !DILocation(line: 7, column: 21, scope: !20, inlinedAt: !45)
!48 = !{!39, !43}
!49 = !DILocation(line: 7, column: 5, scope: !20, inlinedAt: !45)
!50 = !DILocation(line: 7, column: 10, scope: !20, inlinedAt: !45)
!51 = !DILocation(line: 6, column: 26, scope: !20, inlinedAt: !45)
!52 = !DILocation(line: 6, column: 21, scope: !20, inlinedAt: !45)
!53 = distinct !{!53, !44, !54, !34}
!54 = !DILocation(line: 7, column: 49, scope: !20, inlinedAt: !45)
!55 = !DILocation(line: 14, column: 1, scope: !10)
!56 = !DISubprogram(name: "transform", scope: !8, file: !8, line: 1, type: !11, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !12)
