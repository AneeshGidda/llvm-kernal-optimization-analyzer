; ModuleID = 'libcalls.c'
source_filename = "libcalls.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local void @release_all(ptr nocapture noundef readonly %p, i32 noundef %n) local_unnamed_addr #0 !dbg !9 {
entry:
  %cmp3 = icmp sgt i32 %n, 0, !dbg !12
  br i1 %cmp3, label %for.body.preheader, label %for.cond.cleanup, !dbg !13

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !12
  br label %for.body, !dbg !13

for.cond.cleanup:                                 ; preds = %for.body, %entry
  ret void, !dbg !14

for.body:                                         ; preds = %for.body.preheader, %for.body
  %indvars.iv = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next, %for.body ]
  %arrayidx = getelementptr inbounds ptr, ptr %p, i64 %indvars.iv, !dbg !15
  %0 = load ptr, ptr %arrayidx, align 8, !dbg !15, !tbaa !16
  tail call void @free(ptr noundef %0), !dbg !20
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !21
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !12
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !13, !llvm.loop !22
}

; Function Attrs: inaccessiblemem_or_argmemonly mustprogress nounwind willreturn allockind("free")
declare void @free(ptr allocptr nocapture noundef) local_unnamed_addr #1

; Function Attrs: nofree nounwind uwtable
define dso_local void @lengths(ptr noalias nocapture noundef writeonly %out, ptr noalias nocapture noundef readonly %s, i32 noundef %n) local_unnamed_addr #2 !dbg !25 {
entry:
  %cmp6 = icmp sgt i32 %n, 0, !dbg !26
  br i1 %cmp6, label %for.body.preheader, label %for.cond.cleanup, !dbg !27

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !26
  br label %for.body, !dbg !27

for.cond.cleanup:                                 ; preds = %for.body, %entry
  ret void, !dbg !28

for.body:                                         ; preds = %for.body.preheader, %for.body
  %indvars.iv = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next, %for.body ]
  %arrayidx = getelementptr inbounds ptr, ptr %s, i64 %indvars.iv, !dbg !29
  %0 = load ptr, ptr %arrayidx, align 8, !dbg !29, !tbaa !16
  %call = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %0), !dbg !30
  %arrayidx2 = getelementptr inbounds i64, ptr %out, i64 %indvars.iv, !dbg !31
  store i64 %call, ptr %arrayidx2, align 8, !dbg !32, !tbaa !33
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !35
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !26
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !27, !llvm.loop !36
}

; Function Attrs: argmemonly mustprogress nofree nounwind readonly willreturn
declare i64 @strlen(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: nofree nounwind uwtable
define dso_local void @apply_sin(ptr noalias nocapture noundef writeonly %y, ptr noalias nocapture noundef readonly %x, i32 noundef %n) local_unnamed_addr #2 !dbg !38 {
entry:
  %cmp6 = icmp sgt i32 %n, 0, !dbg !39
  br i1 %cmp6, label %for.body.preheader, label %for.cond.cleanup, !dbg !40

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !39
  %0 = add nsw i64 %wide.trip.count, -1, !dbg !40
  %xtraiter = and i64 %wide.trip.count, 3, !dbg !40
  %1 = icmp ult i64 %0, 3, !dbg !40
  br i1 %1, label %for.cond.cleanup.loopexit.unr-lcssa, label %for.body.preheader.new, !dbg !40

for.body.preheader.new:                           ; preds = %for.body.preheader
  %unroll_iter = and i64 %wide.trip.count, 4294967292, !dbg !40
  br label %for.body, !dbg !40

for.cond.cleanup.loopexit.unr-lcssa:              ; preds = %for.body, %for.body.preheader
  %indvars.iv.unr = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next.3, %for.body ]
  %lcmp.mod.not = icmp eq i64 %xtraiter, 0, !dbg !40
  br i1 %lcmp.mod.not, label %for.cond.cleanup, label %for.body.epil, !dbg !40

for.body.epil:                                    ; preds = %for.cond.cleanup.loopexit.unr-lcssa, %for.body.epil
  %indvars.iv.epil = phi i64 [ %indvars.iv.next.epil, %for.body.epil ], [ %indvars.iv.unr, %for.cond.cleanup.loopexit.unr-lcssa ]
  %epil.iter = phi i64 [ %epil.iter.next, %for.body.epil ], [ 0, %for.cond.cleanup.loopexit.unr-lcssa ]
  %arrayidx.epil = getelementptr inbounds float, ptr %x, i64 %indvars.iv.epil, !dbg !41
  %2 = load float, ptr %arrayidx.epil, align 4, !dbg !41, !tbaa !42
  %call.epil = tail call float @sinf(float noundef %2) #5, !dbg !44
  %arrayidx2.epil = getelementptr inbounds float, ptr %y, i64 %indvars.iv.epil, !dbg !45
  store float %call.epil, ptr %arrayidx2.epil, align 4, !dbg !46, !tbaa !42
  %indvars.iv.next.epil = add nuw nsw i64 %indvars.iv.epil, 1, !dbg !47
  %epil.iter.next = add i64 %epil.iter, 1, !dbg !40
  %epil.iter.cmp.not = icmp eq i64 %epil.iter.next, %xtraiter, !dbg !40
  br i1 %epil.iter.cmp.not, label %for.cond.cleanup, label %for.body.epil, !dbg !40, !llvm.loop !48

for.cond.cleanup:                                 ; preds = %for.cond.cleanup.loopexit.unr-lcssa, %for.body.epil, %entry
  ret void, !dbg !50

for.body:                                         ; preds = %for.body, %for.body.preheader.new
  %indvars.iv = phi i64 [ 0, %for.body.preheader.new ], [ %indvars.iv.next.3, %for.body ]
  %niter = phi i64 [ 0, %for.body.preheader.new ], [ %niter.next.3, %for.body ]
  %arrayidx = getelementptr inbounds float, ptr %x, i64 %indvars.iv, !dbg !41
  %3 = load float, ptr %arrayidx, align 4, !dbg !41, !tbaa !42
  %call = tail call float @sinf(float noundef %3) #5, !dbg !44
  %arrayidx2 = getelementptr inbounds float, ptr %y, i64 %indvars.iv, !dbg !45
  store float %call, ptr %arrayidx2, align 4, !dbg !46, !tbaa !42
  %indvars.iv.next = or i64 %indvars.iv, 1, !dbg !47
  %arrayidx.1 = getelementptr inbounds float, ptr %x, i64 %indvars.iv.next, !dbg !41
  %4 = load float, ptr %arrayidx.1, align 4, !dbg !41, !tbaa !42
  %call.1 = tail call float @sinf(float noundef %4) #5, !dbg !44
  %arrayidx2.1 = getelementptr inbounds float, ptr %y, i64 %indvars.iv.next, !dbg !45
  store float %call.1, ptr %arrayidx2.1, align 4, !dbg !46, !tbaa !42
  %indvars.iv.next.1 = or i64 %indvars.iv, 2, !dbg !47
  %arrayidx.2 = getelementptr inbounds float, ptr %x, i64 %indvars.iv.next.1, !dbg !41
  %5 = load float, ptr %arrayidx.2, align 4, !dbg !41, !tbaa !42
  %call.2 = tail call float @sinf(float noundef %5) #5, !dbg !44
  %arrayidx2.2 = getelementptr inbounds float, ptr %y, i64 %indvars.iv.next.1, !dbg !45
  store float %call.2, ptr %arrayidx2.2, align 4, !dbg !46, !tbaa !42
  %indvars.iv.next.2 = or i64 %indvars.iv, 3, !dbg !47
  %arrayidx.3 = getelementptr inbounds float, ptr %x, i64 %indvars.iv.next.2, !dbg !41
  %6 = load float, ptr %arrayidx.3, align 4, !dbg !41, !tbaa !42
  %call.3 = tail call float @sinf(float noundef %6) #5, !dbg !44
  %arrayidx2.3 = getelementptr inbounds float, ptr %y, i64 %indvars.iv.next.2, !dbg !45
  store float %call.3, ptr %arrayidx2.3, align 4, !dbg !46, !tbaa !42
  %indvars.iv.next.3 = add nuw nsw i64 %indvars.iv, 4, !dbg !47
  %niter.next.3 = add i64 %niter, 4, !dbg !40
  %niter.ncmp.3 = icmp eq i64 %niter.next.3, %unroll_iter, !dbg !40
  br i1 %niter.ncmp.3, label %for.cond.cleanup.loopexit.unr-lcssa, label %for.body, !dbg !40, !llvm.loop !51
}

; Function Attrs: mustprogress nofree nounwind willreturn writeonly
declare float @sinf(float noundef) local_unnamed_addr #4

attributes #0 = { nounwind uwtable "frame-pointer"="none" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { inaccessiblemem_or_argmemonly mustprogress nounwind willreturn allockind("free") "alloc-family"="malloc" "frame-pointer"="none" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind uwtable "frame-pointer"="none" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { argmemonly mustprogress nofree nounwind readonly willreturn "frame-pointer"="none" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree nounwind willreturn writeonly "frame-pointer"="none" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7}
!llvm.ident = !{!8}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "Homebrew clang version 15.0.7", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "libcalls.c", directory: ".", checksumkind: CSK_MD5, checksum: "67debe46cc3629e097e146028abcf63c")
!2 = !{i32 7, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 7, !"PIC Level", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{i32 7, !"uwtable", i32 2}
!8 = !{!"Homebrew clang version 15.0.7"}
!9 = distinct !DISubprogram(name: "release_all", scope: !1, file: !1, line: 6, type: !10, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !11)
!10 = !DISubroutineType(types: !11)
!11 = !{}
!12 = !DILocation(line: 7, column: 21, scope: !9)
!13 = !DILocation(line: 7, column: 3, scope: !9)
!14 = !DILocation(line: 9, column: 1, scope: !9)
!15 = !DILocation(line: 8, column: 10, scope: !9)
!16 = !{!17, !17, i64 0}
!17 = !{!"any pointer", !18, i64 0}
!18 = !{!"omnipotent char", !19, i64 0}
!19 = !{!"Simple C/C++ TBAA"}
!20 = !DILocation(line: 8, column: 5, scope: !9)
!21 = !DILocation(line: 7, column: 26, scope: !9)
!22 = distinct !{!22, !13, !23, !24}
!23 = !DILocation(line: 8, column: 14, scope: !9)
!24 = !{!"llvm.loop.mustprogress"}
!25 = distinct !DISubprogram(name: "lengths", scope: !1, file: !1, line: 10, type: !10, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !11)
!26 = !DILocation(line: 11, column: 21, scope: !25)
!27 = !DILocation(line: 11, column: 3, scope: !25)
!28 = !DILocation(line: 13, column: 1, scope: !25)
!29 = !DILocation(line: 12, column: 21, scope: !25)
!30 = !DILocation(line: 12, column: 14, scope: !25)
!31 = !DILocation(line: 12, column: 5, scope: !25)
!32 = !DILocation(line: 12, column: 12, scope: !25)
!33 = !{!34, !34, i64 0}
!34 = !{!"long", !18, i64 0}
!35 = !DILocation(line: 11, column: 26, scope: !25)
!36 = distinct !{!36, !27, !37, !24}
!37 = !DILocation(line: 12, column: 25, scope: !25)
!38 = distinct !DISubprogram(name: "apply_sin", scope: !1, file: !1, line: 16, type: !10, scopeLine: 16, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !11)
!39 = !DILocation(line: 17, column: 21, scope: !38)
!40 = !DILocation(line: 17, column: 3, scope: !38)
!41 = !DILocation(line: 18, column: 17, scope: !38)
!42 = !{!43, !43, i64 0}
!43 = !{!"float", !18, i64 0}
!44 = !DILocation(line: 18, column: 12, scope: !38)
!45 = !DILocation(line: 18, column: 5, scope: !38)
!46 = !DILocation(line: 18, column: 10, scope: !38)
!47 = !DILocation(line: 17, column: 26, scope: !38)
!48 = distinct !{!48, !49}
!49 = !{!"llvm.loop.unroll.disable"}
!50 = !DILocation(line: 19, column: 1, scope: !38)
!51 = distinct !{!51, !40, !52, !24}
!52 = !DILocation(line: 18, column: 21, scope: !38)
