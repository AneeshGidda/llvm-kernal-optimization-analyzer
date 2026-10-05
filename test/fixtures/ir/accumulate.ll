; ModuleID = 'accumulate.c'
source_filename = "accumulate.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree norecurse nosync nounwind ssp uwtable
define void @accumulate(ptr nocapture noundef %out, ptr nocapture noundef readonly %a, i32 noundef %n) local_unnamed_addr #0 !dbg !10 {
entry:
  %cmp3 = icmp sgt i32 %n, 0, !dbg !13
  br i1 %cmp3, label %for.body.preheader, label %for.cond.cleanup, !dbg !14

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !13
  %.pre = load float, ptr %out, align 4, !dbg !15, !tbaa !16
  br label %for.body, !dbg !14

for.cond.cleanup:                                 ; preds = %for.body, %entry
  ret void, !dbg !20

for.body:                                         ; preds = %for.body.preheader, %for.body
  %0 = phi float [ %.pre, %for.body.preheader ], [ %add, %for.body ], !dbg !15
  %indvars.iv = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next, %for.body ]
  %arrayidx = getelementptr inbounds float, ptr %a, i64 %indvars.iv, !dbg !21
  %1 = load float, ptr %arrayidx, align 4, !dbg !21, !tbaa !16
  %add = fadd float %1, %0, !dbg !15
  store float %add, ptr %out, align 4, !dbg !15, !tbaa !16
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !22
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !13
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !14, !llvm.loop !23
}

; Function Attrs: argmemonly nofree norecurse nosync nounwind ssp uwtable
define void @scale_by_ptr(ptr nocapture noundef %y, ptr nocapture noundef readonly %scale, i32 noundef %n) local_unnamed_addr #0 !dbg !26 {
entry:
  %cmp7 = icmp sgt i32 %n, 0, !dbg !27
  br i1 %cmp7, label %for.body.preheader, label %for.cond.cleanup, !dbg !28

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !27
  %min.iters.check = icmp ult i32 %n, 8, !dbg !28
  br i1 %min.iters.check, label %for.body.preheader14, label %vector.memcheck, !dbg !28

vector.memcheck:                                  ; preds = %for.body.preheader
  %0 = shl nuw nsw i64 %wide.trip.count, 2, !dbg !28
  %uglygep = getelementptr i8, ptr %y, i64 %0, !dbg !28
  %uglygep10 = getelementptr i8, ptr %scale, i64 4, !dbg !28
  %bound0 = icmp ugt ptr %uglygep10, %y, !dbg !28
  %bound1 = icmp ugt ptr %uglygep, %scale, !dbg !28
  %found.conflict = and i1 %bound0, %bound1, !dbg !28
  br i1 %found.conflict, label %for.body.preheader14, label %vector.ph, !dbg !28

vector.ph:                                        ; preds = %vector.memcheck
  %n.vec = and i64 %wide.trip.count, 4294967288, !dbg !28
  %1 = load float, ptr %scale, align 4, !tbaa !16, !alias.scope !29
  %broadcast.splatinsert = insertelement <4 x float> poison, float %1, i64 0
  %broadcast.splat = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <4 x i32> zeroinitializer
  %broadcast.splatinsert12 = insertelement <4 x float> poison, float %1, i64 0
  %broadcast.splat13 = shufflevector <4 x float> %broadcast.splatinsert12, <4 x float> poison, <4 x i32> zeroinitializer
  br label %vector.body, !dbg !28

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ], !dbg !32
  %2 = getelementptr inbounds float, ptr %y, i64 %index, !dbg !33
  %wide.load = load <4 x float>, ptr %2, align 4, !dbg !33, !tbaa !16, !alias.scope !34, !noalias !29
  %3 = getelementptr inbounds float, ptr %2, i64 4, !dbg !33
  %wide.load11 = load <4 x float>, ptr %3, align 4, !dbg !33, !tbaa !16, !alias.scope !34, !noalias !29
  %4 = fmul <4 x float> %wide.load, %broadcast.splat, !dbg !28
  %5 = fmul <4 x float> %wide.load11, %broadcast.splat13, !dbg !28
  store <4 x float> %4, ptr %2, align 4, !dbg !36, !tbaa !16, !alias.scope !34, !noalias !29
  store <4 x float> %5, ptr %3, align 4, !dbg !36, !tbaa !16, !alias.scope !34, !noalias !29
  %index.next = add nuw i64 %index, 8, !dbg !32
  %6 = icmp eq i64 %index.next, %n.vec, !dbg !32
  br i1 %6, label %middle.block, label %vector.body, !dbg !32, !llvm.loop !37

middle.block:                                     ; preds = %vector.body
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count, !dbg !28
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader14, !dbg !28

for.body.preheader14:                             ; preds = %vector.memcheck, %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %vector.memcheck ], [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  br label %for.body, !dbg !28

for.cond.cleanup:                                 ; preds = %for.body, %middle.block, %entry
  ret void, !dbg !40

for.body:                                         ; preds = %for.body.preheader14, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ %indvars.iv.ph, %for.body.preheader14 ]
  %arrayidx = getelementptr inbounds float, ptr %y, i64 %indvars.iv, !dbg !33
  %7 = load float, ptr %arrayidx, align 4, !dbg !33, !tbaa !16
  %8 = load float, ptr %scale, align 4, !dbg !41, !tbaa !16
  %mul = fmul float %7, %8, !dbg !42
  store float %mul, ptr %arrayidx, align 4, !dbg !36, !tbaa !16
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !32
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !27
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !28, !llvm.loop !43
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
!8 = !DIFile(filename: "accumulate.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "accumulate", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 4, column: 21, scope: !10)
!14 = !DILocation(line: 4, column: 3, scope: !10)
!15 = !DILocation(line: 5, column: 10, scope: !10)
!16 = !{!17, !17, i64 0}
!17 = !{!"float", !18, i64 0}
!18 = !{!"omnipotent char", !19, i64 0}
!19 = !{!"Simple C/C++ TBAA"}
!20 = !DILocation(line: 6, column: 1, scope: !10)
!21 = !DILocation(line: 5, column: 13, scope: !10)
!22 = !DILocation(line: 4, column: 26, scope: !10)
!23 = distinct !{!23, !14, !24, !25}
!24 = !DILocation(line: 5, column: 16, scope: !10)
!25 = !{!"llvm.loop.mustprogress"}
!26 = distinct !DISubprogram(name: "scale_by_ptr", scope: !8, file: !8, line: 9, type: !11, scopeLine: 9, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!27 = !DILocation(line: 10, column: 21, scope: !26)
!28 = !DILocation(line: 10, column: 3, scope: !26)
!29 = !{!30}
!30 = distinct !{!30, !31}
!31 = distinct !{!31, !"LVerDomain"}
!32 = !DILocation(line: 10, column: 26, scope: !26)
!33 = !DILocation(line: 11, column: 12, scope: !26)
!34 = !{!35}
!35 = distinct !{!35, !31}
!36 = !DILocation(line: 11, column: 10, scope: !26)
!37 = distinct !{!37, !28, !38, !25, !39}
!38 = !DILocation(line: 11, column: 20, scope: !26)
!39 = !{!"llvm.loop.isvectorized", i32 1}
!40 = !DILocation(line: 12, column: 1, scope: !26)
!41 = !DILocation(line: 11, column: 19, scope: !26)
!42 = !DILocation(line: 11, column: 17, scope: !26)
!43 = distinct !{!43, !28, !38, !25, !39}
