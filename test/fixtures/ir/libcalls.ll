; ModuleID = 'libcalls.c'
source_filename = "libcalls.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: nounwind ssp uwtable
define void @release_all(ptr nocapture noundef readonly %p, i32 noundef %n) local_unnamed_addr #0 !dbg !10 {
entry:
  %cmp3 = icmp sgt i32 %n, 0, !dbg !13
  br i1 %cmp3, label %for.body.preheader, label %for.cond.cleanup, !dbg !14

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !13
  br label %for.body, !dbg !14

for.cond.cleanup:                                 ; preds = %for.body, %entry
  ret void, !dbg !15

for.body:                                         ; preds = %for.body.preheader, %for.body
  %indvars.iv = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next, %for.body ]
  %arrayidx = getelementptr inbounds ptr, ptr %p, i64 %indvars.iv, !dbg !16
  %0 = load ptr, ptr %arrayidx, align 8, !dbg !16, !tbaa !17
  tail call void @free(ptr noundef %0), !dbg !21
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !22
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !13
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !14, !llvm.loop !23
}

; Function Attrs: inaccessiblemem_or_argmemonly mustprogress nounwind willreturn allockind("free")
declare void @free(ptr allocptr nocapture noundef) local_unnamed_addr #1

; Function Attrs: nofree nounwind ssp uwtable
define void @lengths(ptr noalias nocapture noundef writeonly %out, ptr noalias nocapture noundef readonly %s, i32 noundef %n) local_unnamed_addr #2 !dbg !26 {
entry:
  %cmp6 = icmp sgt i32 %n, 0, !dbg !27
  br i1 %cmp6, label %for.body.preheader, label %for.cond.cleanup, !dbg !28

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !27
  br label %for.body, !dbg !28

for.cond.cleanup:                                 ; preds = %for.body, %entry
  ret void, !dbg !29

for.body:                                         ; preds = %for.body.preheader, %for.body
  %indvars.iv = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next, %for.body ]
  %arrayidx = getelementptr inbounds ptr, ptr %s, i64 %indvars.iv, !dbg !30
  %0 = load ptr, ptr %arrayidx, align 8, !dbg !30, !tbaa !17
  %call = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %0), !dbg !31
  %arrayidx2 = getelementptr inbounds i64, ptr %out, i64 %indvars.iv, !dbg !32
  store i64 %call, ptr %arrayidx2, align 8, !dbg !33, !tbaa !34
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !36
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !27
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !28, !llvm.loop !37
}

; Function Attrs: argmemonly mustprogress nofree nounwind readonly willreturn
declare i64 @strlen(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: argmemonly nofree nosync nounwind ssp uwtable
define void @apply_sin(ptr noalias nocapture noundef writeonly %y, ptr noalias nocapture noundef readonly %x, i32 noundef %n) local_unnamed_addr #4 !dbg !39 {
entry:
  %cmp6 = icmp sgt i32 %n, 0, !dbg !40
  br i1 %cmp6, label %for.body.preheader, label %for.cond.cleanup, !dbg !41

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !40
  %min.iters.check = icmp eq i32 %n, 1, !dbg !41
  br i1 %min.iters.check, label %for.body.preheader9, label %vector.ph, !dbg !41

vector.ph:                                        ; preds = %for.body.preheader
  %n.vec = and i64 %wide.trip.count, 4294967294, !dbg !41
  br label %vector.body, !dbg !41

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ], !dbg !42
  %0 = getelementptr inbounds float, ptr %x, i64 %index, !dbg !43
  %wide.load = load <2 x float>, ptr %0, align 4, !dbg !43, !tbaa !44
  %1 = tail call <2 x float> @llvm.sin.v2f32(<2 x float> %wide.load), !dbg !46
  %2 = getelementptr inbounds float, ptr %y, i64 %index, !dbg !47
  store <2 x float> %1, ptr %2, align 4, !dbg !48, !tbaa !44
  %index.next = add nuw i64 %index, 2, !dbg !42
  %3 = icmp eq i64 %index.next, %n.vec, !dbg !42
  br i1 %3, label %middle.block, label %vector.body, !dbg !42, !llvm.loop !49

middle.block:                                     ; preds = %vector.body
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count, !dbg !41
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader9, !dbg !41

for.body.preheader9:                              ; preds = %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  br label %for.body, !dbg !41

for.cond.cleanup:                                 ; preds = %for.body, %middle.block, %entry
  ret void, !dbg !52

for.body:                                         ; preds = %for.body.preheader9, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ %indvars.iv.ph, %for.body.preheader9 ]
  %arrayidx = getelementptr inbounds float, ptr %x, i64 %indvars.iv, !dbg !43
  %4 = load float, ptr %arrayidx, align 4, !dbg !43, !tbaa !44
  %5 = tail call float @llvm.sin.f32(float %4), !dbg !46
  %arrayidx2 = getelementptr inbounds float, ptr %y, i64 %indvars.iv, !dbg !47
  store float %5, ptr %arrayidx2, align 4, !dbg !48, !tbaa !44
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !42
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !40
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !41, !llvm.loop !53
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare float @llvm.sin.f32(float) #5

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare <2 x float> @llvm.sin.v2f32(<2 x float>) #6

attributes #0 = { nounwind ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #1 = { inaccessiblemem_or_argmemonly mustprogress nounwind willreturn allockind("free") "alloc-family"="malloc" "frame-pointer"="non-leaf" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #2 = { nofree nounwind ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #3 = { argmemonly mustprogress nofree nounwind readonly willreturn "frame-pointer"="non-leaf" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #4 = { argmemonly nofree nosync nounwind ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #5 = { mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn }
attributes #6 = { nocallback nofree nosync nounwind readnone speculatable willreturn }

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
!8 = !DIFile(filename: "libcalls.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "release_all", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 7, column: 21, scope: !10)
!14 = !DILocation(line: 7, column: 3, scope: !10)
!15 = !DILocation(line: 9, column: 1, scope: !10)
!16 = !DILocation(line: 8, column: 10, scope: !10)
!17 = !{!18, !18, i64 0}
!18 = !{!"any pointer", !19, i64 0}
!19 = !{!"omnipotent char", !20, i64 0}
!20 = !{!"Simple C/C++ TBAA"}
!21 = !DILocation(line: 8, column: 5, scope: !10)
!22 = !DILocation(line: 7, column: 26, scope: !10)
!23 = distinct !{!23, !14, !24, !25}
!24 = !DILocation(line: 8, column: 14, scope: !10)
!25 = !{!"llvm.loop.mustprogress"}
!26 = distinct !DISubprogram(name: "lengths", scope: !8, file: !8, line: 10, type: !11, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!27 = !DILocation(line: 11, column: 21, scope: !26)
!28 = !DILocation(line: 11, column: 3, scope: !26)
!29 = !DILocation(line: 13, column: 1, scope: !26)
!30 = !DILocation(line: 12, column: 21, scope: !26)
!31 = !DILocation(line: 12, column: 14, scope: !26)
!32 = !DILocation(line: 12, column: 5, scope: !26)
!33 = !DILocation(line: 12, column: 12, scope: !26)
!34 = !{!35, !35, i64 0}
!35 = !{!"long", !19, i64 0}
!36 = !DILocation(line: 11, column: 26, scope: !26)
!37 = distinct !{!37, !28, !38, !25}
!38 = !DILocation(line: 12, column: 25, scope: !26)
!39 = distinct !DISubprogram(name: "apply_sin", scope: !8, file: !8, line: 16, type: !11, scopeLine: 16, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!40 = !DILocation(line: 17, column: 21, scope: !39)
!41 = !DILocation(line: 17, column: 3, scope: !39)
!42 = !DILocation(line: 17, column: 26, scope: !39)
!43 = !DILocation(line: 18, column: 17, scope: !39)
!44 = !{!45, !45, i64 0}
!45 = !{!"float", !19, i64 0}
!46 = !DILocation(line: 18, column: 12, scope: !39)
!47 = !DILocation(line: 18, column: 5, scope: !39)
!48 = !DILocation(line: 18, column: 10, scope: !39)
!49 = distinct !{!49, !41, !50, !25, !51}
!50 = !DILocation(line: 18, column: 21, scope: !39)
!51 = !{!"llvm.loop.isvectorized", i32 1}
!52 = !DILocation(line: 19, column: 1, scope: !39)
!53 = distinct !{!53, !41, !50, !25, !54, !51}
!54 = !{!"llvm.loop.unroll.runtime.disable"}
