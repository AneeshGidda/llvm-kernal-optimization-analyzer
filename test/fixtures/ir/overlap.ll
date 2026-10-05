; ModuleID = 'overlap.c'
source_filename = "overlap.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree norecurse nosync nounwind ssp uwtable
define void @self_dep(ptr nocapture noundef %a, i32 noundef %n) local_unnamed_addr #0 !dbg !10 {
entry:
  %cmp7 = icmp sgt i32 %n, 0, !dbg !13
  br i1 %cmp7, label %for.body.preheader, label %for.cond.cleanup, !dbg !14

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !13
  br label %for.body, !dbg !14

for.cond.cleanup:                                 ; preds = %for.body, %entry
  ret void, !dbg !15

for.body:                                         ; preds = %for.body.preheader, %for.body
  %indvars.iv = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next, %for.body ]
  %arrayidx = getelementptr inbounds float, ptr %a, i64 %indvars.iv, !dbg !16
  %0 = load float, ptr %arrayidx, align 4, !dbg !16, !tbaa !17
  %add = fadd float %0, 1.000000e+00, !dbg !21
  %1 = shl nuw nsw i64 %indvars.iv, 1, !dbg !22
  %arrayidx2 = getelementptr inbounds float, ptr %a, i64 %1, !dbg !23
  store float %add, ptr %arrayidx2, align 4, !dbg !24, !tbaa !17
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !25
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !13
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !14, !llvm.loop !26
}

; Function Attrs: argmemonly nofree norecurse nosync nounwind ssp uwtable
define void @histogram(ptr nocapture noundef %h, ptr nocapture noundef readonly %idx, i32 noundef %n) local_unnamed_addr #0 !dbg !29 {
entry:
  %cmp6 = icmp sgt i32 %n, 0, !dbg !30
  br i1 %cmp6, label %for.body.preheader, label %for.cond.cleanup, !dbg !31

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !30
  br label %for.body, !dbg !31

for.cond.cleanup:                                 ; preds = %for.body, %entry
  ret void, !dbg !32

for.body:                                         ; preds = %for.body.preheader, %for.body
  %indvars.iv = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next, %for.body ]
  %arrayidx = getelementptr inbounds i32, ptr %idx, i64 %indvars.iv, !dbg !33
  %0 = load i32, ptr %arrayidx, align 4, !dbg !33, !tbaa !34
  %idxprom1 = sext i32 %0 to i64, !dbg !36
  %arrayidx2 = getelementptr inbounds i32, ptr %h, i64 %idxprom1, !dbg !36
  %1 = load i32, ptr %arrayidx2, align 4, !dbg !37, !tbaa !34
  %inc = add nsw i32 %1, 1, !dbg !37
  store i32 %inc, ptr %arrayidx2, align 4, !dbg !37, !tbaa !34
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !38
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !30
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !31, !llvm.loop !39
}

; Function Attrs: argmemonly nofree norecurse nosync nounwind ssp uwtable
define void @stencil_rows(ptr noalias nocapture noundef %A, i32 noundef %n, i32 noundef %m, i32 noundef %k) local_unnamed_addr #0 !dbg !40 {
entry:
  %cmp25 = icmp sgt i32 %n, 0, !dbg !41
  br i1 %cmp25, label %for.cond1.preheader.lr.ph, label %for.cond.cleanup, !dbg !42

for.cond1.preheader.lr.ph:                        ; preds = %entry
  %cmp223 = icmp sgt i32 %m, 0
  %0 = sext i32 %k to i64, !dbg !42
  %1 = sext i32 %m to i64, !dbg !42
  %wide.trip.count36 = zext i32 %n to i64, !dbg !41
  %wide.trip.count = zext i32 %m to i64
  %2 = shl nsw i64 %1, 2, !dbg !43
  %3 = shl nuw nsw i64 %wide.trip.count, 2, !dbg !42
  %4 = mul nsw i64 %0, %1, !dbg !42
  %5 = shl i64 %4, 2, !dbg !42
  %6 = add i64 %5, %3, !dbg !42
  %min.iters.check = icmp ult i32 %m, 8
  %n.vec = and i64 %wide.trip.count, 4294967288
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count
  br label %for.cond1.preheader, !dbg !42

for.cond1.preheader:                              ; preds = %for.cond1.preheader.lr.ph, %for.cond.cleanup3
  %indvars.iv30 = phi i64 [ 0, %for.cond1.preheader.lr.ph ], [ %indvars.iv.next31, %for.cond.cleanup3 ]
  %7 = mul i64 %2, %indvars.iv30, !dbg !43
  %uglygep = getelementptr i8, ptr %A, i64 %7, !dbg !43
  %8 = add i64 %3, %7, !dbg !43
  %uglygep38 = getelementptr i8, ptr %A, i64 %8, !dbg !43
  %9 = add i64 %5, %7, !dbg !43
  %uglygep39 = getelementptr i8, ptr %A, i64 %9, !dbg !43
  %10 = add i64 %6, %7, !dbg !43
  %uglygep40 = getelementptr i8, ptr %A, i64 %10, !dbg !43
  br i1 %cmp223, label %for.body4.lr.ph, label %for.cond.cleanup3, !dbg !43

for.body4.lr.ph:                                  ; preds = %for.cond1.preheader
  %11 = add nsw i64 %indvars.iv30, %0
  %12 = mul nsw i64 %11, %1
  %13 = mul nsw i64 %indvars.iv30, %1
  br i1 %min.iters.check, label %for.body4.preheader, label %vector.memcheck, !dbg !43

vector.memcheck:                                  ; preds = %for.body4.lr.ph
  %bound0 = icmp ult ptr %uglygep, %uglygep40, !dbg !43
  %bound1 = icmp ult ptr %uglygep39, %uglygep38, !dbg !43
  %found.conflict = and i1 %bound0, %bound1, !dbg !43
  br i1 %found.conflict, label %for.body4.preheader, label %vector.body, !dbg !43

vector.body:                                      ; preds = %vector.memcheck, %vector.body
  %index = phi i64 [ %index.next, %vector.body ], [ 0, %vector.memcheck ], !dbg !44
  %14 = add nsw i64 %index, %12, !dbg !45
  %15 = getelementptr inbounds float, ptr %A, i64 %14, !dbg !46
  %wide.load = load <4 x float>, ptr %15, align 4, !dbg !46, !tbaa !17, !alias.scope !47
  %16 = getelementptr inbounds float, ptr %15, i64 4, !dbg !46
  %wide.load41 = load <4 x float>, ptr %16, align 4, !dbg !46, !tbaa !17, !alias.scope !47
  %17 = add nsw i64 %index, %13, !dbg !50
  %18 = getelementptr inbounds float, ptr %A, i64 %17, !dbg !51
  %wide.load42 = load <4 x float>, ptr %18, align 4, !dbg !52, !tbaa !17, !alias.scope !53, !noalias !47
  %19 = getelementptr inbounds float, ptr %18, i64 4, !dbg !52
  %wide.load43 = load <4 x float>, ptr %19, align 4, !dbg !52, !tbaa !17, !alias.scope !53, !noalias !47
  %20 = fadd <4 x float> %wide.load, %wide.load42, !dbg !52
  %21 = fadd <4 x float> %wide.load41, %wide.load43, !dbg !52
  store <4 x float> %20, ptr %18, align 4, !dbg !52, !tbaa !17, !alias.scope !53, !noalias !47
  store <4 x float> %21, ptr %19, align 4, !dbg !52, !tbaa !17, !alias.scope !53, !noalias !47
  %index.next = add nuw i64 %index, 8, !dbg !44
  %22 = icmp eq i64 %index.next, %n.vec, !dbg !44
  br i1 %22, label %middle.block, label %vector.body, !dbg !44, !llvm.loop !55

middle.block:                                     ; preds = %vector.body
  br i1 %cmp.n, label %for.cond.cleanup3, label %for.body4.preheader, !dbg !43

for.body4.preheader:                              ; preds = %vector.memcheck, %for.body4.lr.ph, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %vector.memcheck ], [ 0, %for.body4.lr.ph ], [ %n.vec, %middle.block ]
  br label %for.body4, !dbg !43

for.cond.cleanup:                                 ; preds = %for.cond.cleanup3, %entry
  ret void, !dbg !58

for.cond.cleanup3:                                ; preds = %for.body4, %middle.block, %for.cond1.preheader
  %indvars.iv.next31 = add nuw nsw i64 %indvars.iv30, 1, !dbg !59
  %exitcond37.not = icmp eq i64 %indvars.iv.next31, %wide.trip.count36, !dbg !41
  br i1 %exitcond37.not, label %for.cond.cleanup, label %for.cond1.preheader, !dbg !42, !llvm.loop !60

for.body4:                                        ; preds = %for.body4.preheader, %for.body4
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body4 ], [ %indvars.iv.ph, %for.body4.preheader ]
  %23 = add nsw i64 %indvars.iv, %12, !dbg !45
  %arrayidx = getelementptr inbounds float, ptr %A, i64 %23, !dbg !46
  %24 = load float, ptr %arrayidx, align 4, !dbg !46, !tbaa !17
  %25 = add nsw i64 %indvars.iv, %13, !dbg !50
  %arrayidx9 = getelementptr inbounds float, ptr %A, i64 %25, !dbg !51
  %26 = load float, ptr %arrayidx9, align 4, !dbg !52, !tbaa !17
  %add10 = fadd float %24, %26, !dbg !52
  store float %add10, ptr %arrayidx9, align 4, !dbg !52, !tbaa !17
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !44
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !61
  br i1 %exitcond.not, label %for.cond.cleanup3, label %for.body4, !dbg !43, !llvm.loop !62
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
!8 = !DIFile(filename: "overlap.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "self_dep", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 3, column: 21, scope: !10)
!14 = !DILocation(line: 3, column: 3, scope: !10)
!15 = !DILocation(line: 5, column: 1, scope: !10)
!16 = !DILocation(line: 4, column: 16, scope: !10)
!17 = !{!18, !18, i64 0}
!18 = !{!"float", !19, i64 0}
!19 = !{!"omnipotent char", !20, i64 0}
!20 = !{!"Simple C/C++ TBAA"}
!21 = !DILocation(line: 4, column: 21, scope: !10)
!22 = !DILocation(line: 4, column: 9, scope: !10)
!23 = !DILocation(line: 4, column: 5, scope: !10)
!24 = !DILocation(line: 4, column: 14, scope: !10)
!25 = !DILocation(line: 3, column: 26, scope: !10)
!26 = distinct !{!26, !14, !27, !28}
!27 = !DILocation(line: 4, column: 23, scope: !10)
!28 = !{!"llvm.loop.mustprogress"}
!29 = distinct !DISubprogram(name: "histogram", scope: !8, file: !8, line: 8, type: !11, scopeLine: 8, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!30 = !DILocation(line: 9, column: 21, scope: !29)
!31 = !DILocation(line: 9, column: 3, scope: !29)
!32 = !DILocation(line: 11, column: 1, scope: !29)
!33 = !DILocation(line: 10, column: 7, scope: !29)
!34 = !{!35, !35, i64 0}
!35 = !{!"int", !19, i64 0}
!36 = !DILocation(line: 10, column: 5, scope: !29)
!37 = !DILocation(line: 10, column: 14, scope: !29)
!38 = !DILocation(line: 9, column: 26, scope: !29)
!39 = distinct !{!39, !31, !37, !28}
!40 = distinct !DISubprogram(name: "stencil_rows", scope: !8, file: !8, line: 14, type: !11, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!41 = !DILocation(line: 15, column: 21, scope: !40)
!42 = !DILocation(line: 15, column: 3, scope: !40)
!43 = !DILocation(line: 16, column: 5, scope: !40)
!44 = !DILocation(line: 16, column: 28, scope: !40)
!45 = !DILocation(line: 17, column: 37, scope: !40)
!46 = !DILocation(line: 17, column: 23, scope: !40)
!47 = !{!48}
!48 = distinct !{!48, !49}
!49 = distinct !{!49, !"LVerDomain"}
!50 = !DILocation(line: 17, column: 15, scope: !40)
!51 = !DILocation(line: 17, column: 7, scope: !40)
!52 = !DILocation(line: 17, column: 20, scope: !40)
!53 = !{!54}
!54 = distinct !{!54, !49}
!55 = distinct !{!55, !43, !56, !28, !57}
!56 = !DILocation(line: 17, column: 40, scope: !40)
!57 = !{!"llvm.loop.isvectorized", i32 1}
!58 = !DILocation(line: 18, column: 1, scope: !40)
!59 = !DILocation(line: 15, column: 26, scope: !40)
!60 = distinct !{!60, !42, !56, !28}
!61 = !DILocation(line: 16, column: 23, scope: !40)
!62 = distinct !{!62, !43, !56, !28, !57}
