; ModuleID = 'conditional.c'
source_filename = "conditional.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree norecurse nosync nounwind ssp uwtable
define void @last_positive(ptr nocapture noundef readonly %a, ptr nocapture noundef writeonly %last, i32 noundef %n) local_unnamed_addr #0 !dbg !10 {
entry:
  %cmp5 = icmp sgt i32 %n, 0, !dbg !13
  br i1 %cmp5, label %for.body.preheader, label %for.cond.cleanup, !dbg !14

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !13
  %min.iters.check = icmp ult i32 %n, 8, !dbg !14
  br i1 %min.iters.check, label %for.body.preheader18, label %vector.memcheck, !dbg !14

vector.memcheck:                                  ; preds = %for.body.preheader
  %uglygep = getelementptr i8, ptr %last, i64 4, !dbg !14
  %0 = shl nuw nsw i64 %wide.trip.count, 2, !dbg !14
  %uglygep8 = getelementptr i8, ptr %a, i64 %0, !dbg !14
  %bound0 = icmp ugt ptr %uglygep8, %last, !dbg !14
  %bound1 = icmp ugt ptr %uglygep, %a, !dbg !14
  %found.conflict = and i1 %bound0, %bound1, !dbg !14
  br i1 %found.conflict, label %for.body.preheader18, label %vector.ph, !dbg !14

vector.ph:                                        ; preds = %vector.memcheck
  %n.vec = and i64 %wide.trip.count, 4294967292, !dbg !14
  br label %vector.body, !dbg !14

vector.body:                                      ; preds = %15, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %15 ], !dbg !15
  %1 = getelementptr inbounds i32, ptr %a, i64 %index, !dbg !16
  %wide.load = load <2 x i32>, ptr %1, align 4, !dbg !16, !tbaa !17, !alias.scope !21
  %2 = getelementptr inbounds i32, ptr %1, i64 2, !dbg !16
  %wide.load9 = load <2 x i32>, ptr %2, align 4, !dbg !16, !tbaa !17, !alias.scope !21
  %3 = icmp sgt <2 x i32> %wide.load, zeroinitializer, !dbg !24
  %4 = icmp sgt <2 x i32> %wide.load9, zeroinitializer, !dbg !24
  %5 = extractelement <2 x i1> %3, i64 0, !dbg !24
  %6 = extractelement <2 x i1> %3, i64 1, !dbg !25
  %7 = or i1 %5, %6, !dbg !25
  %8 = extractelement <2 x i1> %4, i64 0, !dbg !25
  %9 = or i1 %7, %8, !dbg !25
  %10 = extractelement <2 x i1> %4, i64 1, !dbg !25
  %11 = or i1 %9, %10, !dbg !15
  br i1 %11, label %12, label %15, !dbg !15

12:                                               ; preds = %vector.body
  %13 = trunc i64 %index to i32, !dbg !14
  %14 = zext i1 %6 to i32, !dbg !25
  %spec.select16.v = select i1 %8, i32 2, i32 %14, !dbg !25
  %spec.select17.v = select i1 %10, i32 3, i32 %spec.select16.v, !dbg !25
  %spec.select17 = or i32 %spec.select17.v, %13, !dbg !25
  store i32 %spec.select17, ptr %last, align 4, !dbg !15, !tbaa !17, !alias.scope !26, !noalias !21
  br label %15, !dbg !15

15:                                               ; preds = %vector.body, %12
  %index.next = add nuw i64 %index, 4, !dbg !15
  %16 = icmp eq i64 %index.next, %n.vec, !dbg !15
  br i1 %16, label %middle.block, label %vector.body, !dbg !15, !llvm.loop !28

middle.block:                                     ; preds = %15
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count, !dbg !14
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader18, !dbg !14

for.body.preheader18:                             ; preds = %vector.memcheck, %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %vector.memcheck ], [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  br label %for.body, !dbg !14

for.cond.cleanup:                                 ; preds = %for.inc, %middle.block, %entry
  ret void, !dbg !32

for.body:                                         ; preds = %for.body.preheader18, %for.inc
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ %indvars.iv.ph, %for.body.preheader18 ]
  %arrayidx = getelementptr inbounds i32, ptr %a, i64 %indvars.iv, !dbg !16
  %17 = load i32, ptr %arrayidx, align 4, !dbg !16, !tbaa !17
  %cmp1 = icmp sgt i32 %17, 0, !dbg !24
  br i1 %cmp1, label %if.then, label %for.inc, !dbg !16

if.then:                                          ; preds = %for.body
  %18 = trunc i64 %indvars.iv to i32, !dbg !25
  store i32 %18, ptr %last, align 4, !dbg !25, !tbaa !17
  br label %for.inc, !dbg !33

for.inc:                                          ; preds = %for.body, %if.then
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !15
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !13
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !14, !llvm.loop !34
}

; Function Attrs: argmemonly nofree norecurse nosync nounwind ssp uwtable
define void @add_bias(ptr nocapture noundef %y, ptr noundef readonly %bias, i32 noundef %n) local_unnamed_addr #0 !dbg !35 {
entry:
  %cmp4 = icmp sgt i32 %n, 0, !dbg !36
  br i1 %cmp4, label %for.body.lr.ph, label %for.cond.cleanup, !dbg !37

for.body.lr.ph:                                   ; preds = %entry
  %tobool.not = icmp eq ptr %bias, null
  %wide.trip.count = zext i32 %n to i64, !dbg !36
  br label %for.body, !dbg !37

for.cond.cleanup:                                 ; preds = %for.inc, %entry
  ret void, !dbg !38

for.body:                                         ; preds = %for.body.lr.ph, %for.inc
  %indvars.iv = phi i64 [ 0, %for.body.lr.ph ], [ %indvars.iv.next, %for.inc ]
  br i1 %tobool.not, label %for.inc, label %if.then, !dbg !39

if.then:                                          ; preds = %for.body
  %0 = load float, ptr %bias, align 4, !dbg !40, !tbaa !41
  %arrayidx = getelementptr inbounds float, ptr %y, i64 %indvars.iv, !dbg !43
  %1 = load float, ptr %arrayidx, align 4, !dbg !44, !tbaa !41
  %add = fadd float %0, %1, !dbg !44
  store float %add, ptr %arrayidx, align 4, !dbg !44, !tbaa !41
  br label %for.inc, !dbg !43

for.inc:                                          ; preds = %for.body, %if.then
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !45
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !36
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !37, !llvm.loop !46
}

; Function Attrs: nofree nounwind ssp uwtable
define void @count(ptr nocapture noundef %counter, i32 noundef %n) local_unnamed_addr #1 !dbg !48 {
entry:
  %cmp2 = icmp sgt i32 %n, 0, !dbg !49
  br i1 %cmp2, label %for.body.preheader, label %for.cond.cleanup, !dbg !50

for.body.preheader:                               ; preds = %entry
  %.pre = load i32, ptr %counter, align 4, !dbg !51, !tbaa !17
  br label %for.body, !dbg !50

for.cond.cleanup:                                 ; preds = %for.body, %entry
  ret void, !dbg !52

for.body:                                         ; preds = %for.body.preheader, %for.body
  %0 = phi i32 [ %add, %for.body ], [ %.pre, %for.body.preheader ], !dbg !51
  %i.03 = phi i32 [ %inc, %for.body ], [ 0, %for.body.preheader ]
  %call = tail call i32 @peek() #3, !dbg !53
  %add = add nsw i32 %0, %call, !dbg !51
  store i32 %add, ptr %counter, align 4, !dbg !51, !tbaa !17
  %inc = add nuw nsw i32 %i.03, 1, !dbg !54
  %exitcond.not = icmp eq i32 %inc, %n, !dbg !49
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !50, !llvm.loop !55
}

; Function Attrs: mustprogress nofree nounwind readonly willreturn
declare !dbg !57 i32 @peek() local_unnamed_addr #2

attributes #0 = { argmemonly nofree norecurse nosync nounwind ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #1 = { nofree nounwind ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #2 = { mustprogress nofree nounwind readonly willreturn "frame-pointer"="non-leaf" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #3 = { nounwind readonly willreturn }

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
!8 = !DIFile(filename: "conditional.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "last_positive", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 4, column: 21, scope: !10)
!14 = !DILocation(line: 4, column: 3, scope: !10)
!15 = !DILocation(line: 4, column: 26, scope: !10)
!16 = !DILocation(line: 5, column: 9, scope: !10)
!17 = !{!18, !18, i64 0}
!18 = !{!"int", !19, i64 0}
!19 = !{!"omnipotent char", !20, i64 0}
!20 = !{!"Simple C/C++ TBAA"}
!21 = !{!22}
!22 = distinct !{!22, !23}
!23 = distinct !{!23, !"LVerDomain"}
!24 = !DILocation(line: 5, column: 14, scope: !10)
!25 = !DILocation(line: 6, column: 13, scope: !10)
!26 = !{!27}
!27 = distinct !{!27, !23}
!28 = distinct !{!28, !14, !29, !30, !31}
!29 = !DILocation(line: 6, column: 15, scope: !10)
!30 = !{!"llvm.loop.mustprogress"}
!31 = !{!"llvm.loop.isvectorized", i32 1}
!32 = !DILocation(line: 7, column: 1, scope: !10)
!33 = !DILocation(line: 6, column: 7, scope: !10)
!34 = distinct !{!34, !14, !29, !30, !31}
!35 = distinct !DISubprogram(name: "add_bias", scope: !8, file: !8, line: 8, type: !11, scopeLine: 8, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!36 = !DILocation(line: 9, column: 21, scope: !35)
!37 = !DILocation(line: 9, column: 3, scope: !35)
!38 = !DILocation(line: 12, column: 1, scope: !35)
!39 = !DILocation(line: 10, column: 9, scope: !35)
!40 = !DILocation(line: 11, column: 15, scope: !35)
!41 = !{!42, !42, i64 0}
!42 = !{!"float", !19, i64 0}
!43 = !DILocation(line: 11, column: 7, scope: !35)
!44 = !DILocation(line: 11, column: 12, scope: !35)
!45 = !DILocation(line: 9, column: 26, scope: !35)
!46 = distinct !{!46, !37, !47, !30}
!47 = !DILocation(line: 11, column: 16, scope: !35)
!48 = distinct !DISubprogram(name: "count", scope: !8, file: !8, line: 17, type: !11, scopeLine: 17, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!49 = !DILocation(line: 18, column: 21, scope: !48)
!50 = !DILocation(line: 18, column: 3, scope: !48)
!51 = !DILocation(line: 19, column: 14, scope: !48)
!52 = !DILocation(line: 20, column: 1, scope: !48)
!53 = !DILocation(line: 19, column: 17, scope: !48)
!54 = !DILocation(line: 18, column: 26, scope: !48)
!55 = distinct !{!55, !50, !56, !30}
!56 = !DILocation(line: 19, column: 22, scope: !48)
!57 = !DISubprogram(name: "peek", scope: !8, file: !8, line: 16, type: !11, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !12)
