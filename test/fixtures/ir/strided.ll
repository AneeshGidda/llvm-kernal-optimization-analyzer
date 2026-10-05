; ModuleID = 'strided.c'
source_filename = "strided.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree norecurse nosync nounwind ssp uwtable
define void @scal(ptr nocapture noundef %x, float noundef %a, i32 noundef %n, i32 noundef %incx) local_unnamed_addr #0 !dbg !10 {
entry:
  %cmp4 = icmp sgt i32 %n, 0, !dbg !13
  br i1 %cmp4, label %for.body.preheader, label %for.cond.cleanup, !dbg !14

for.body.preheader:                               ; preds = %entry
  %0 = sext i32 %incx to i64, !dbg !14
  %wide.trip.count = zext i32 %n to i64, !dbg !13
  %min.iters.check = icmp ugt i32 %n, 7, !dbg !14
  %ident.check.not = icmp eq i32 %incx, 1, !dbg !14
  %or.cond = and i1 %min.iters.check, %ident.check.not, !dbg !14
  br i1 %or.cond, label %vector.ph, label %for.body.preheader11, !dbg !14

vector.ph:                                        ; preds = %for.body.preheader
  %n.vec = and i64 %wide.trip.count, 4294967288, !dbg !14
  %broadcast.splatinsert = insertelement <4 x float> poison, float %a, i64 0, !dbg !14
  %broadcast.splat = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <4 x i32> zeroinitializer, !dbg !14
  %broadcast.splatinsert9 = insertelement <4 x float> poison, float %a, i64 0, !dbg !14
  %broadcast.splat10 = shufflevector <4 x float> %broadcast.splatinsert9, <4 x float> poison, <4 x i32> zeroinitializer, !dbg !14
  br label %vector.body, !dbg !14

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ], !dbg !15
  %1 = mul nsw i64 %index, %0, !dbg !16
  %2 = getelementptr inbounds float, ptr %x, i64 %1, !dbg !17
  %wide.load = load <4 x float>, ptr %2, align 4, !dbg !18, !tbaa !19
  %3 = getelementptr inbounds float, ptr %2, i64 4, !dbg !18
  %wide.load8 = load <4 x float>, ptr %3, align 4, !dbg !18, !tbaa !19
  %4 = fmul <4 x float> %wide.load, %broadcast.splat, !dbg !18
  %5 = fmul <4 x float> %wide.load8, %broadcast.splat10, !dbg !18
  store <4 x float> %4, ptr %2, align 4, !dbg !18, !tbaa !19
  store <4 x float> %5, ptr %3, align 4, !dbg !18, !tbaa !19
  %index.next = add nuw i64 %index, 8, !dbg !15
  %6 = icmp eq i64 %index.next, %n.vec, !dbg !15
  br i1 %6, label %middle.block, label %vector.body, !dbg !15, !llvm.loop !23

middle.block:                                     ; preds = %vector.body
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count, !dbg !14
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader11, !dbg !14

for.body.preheader11:                             ; preds = %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  br label %for.body, !dbg !14

for.cond.cleanup:                                 ; preds = %for.body, %middle.block, %entry
  ret void, !dbg !27

for.body:                                         ; preds = %for.body.preheader11, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ %indvars.iv.ph, %for.body.preheader11 ]
  %7 = mul nsw i64 %indvars.iv, %0, !dbg !16
  %arrayidx = getelementptr inbounds float, ptr %x, i64 %7, !dbg !17
  %8 = load float, ptr %arrayidx, align 4, !dbg !18, !tbaa !19
  %mul1 = fmul float %8, %a, !dbg !18
  store float %mul1, ptr %arrayidx, align 4, !dbg !18, !tbaa !19
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !15
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !13
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !14, !llvm.loop !28
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
!8 = !DIFile(filename: "strided.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "scal", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 3, column: 21, scope: !10)
!14 = !DILocation(line: 3, column: 3, scope: !10)
!15 = !DILocation(line: 3, column: 26, scope: !10)
!16 = !DILocation(line: 4, column: 9, scope: !10)
!17 = !DILocation(line: 4, column: 5, scope: !10)
!18 = !DILocation(line: 4, column: 17, scope: !10)
!19 = !{!20, !20, i64 0}
!20 = !{!"float", !21, i64 0}
!21 = !{!"omnipotent char", !22, i64 0}
!22 = !{!"Simple C/C++ TBAA"}
!23 = distinct !{!23, !14, !24, !25, !26}
!24 = !DILocation(line: 4, column: 20, scope: !10)
!25 = !{!"llvm.loop.mustprogress"}
!26 = !{!"llvm.loop.isvectorized", i32 1}
!27 = !DILocation(line: 5, column: 1, scope: !10)
!28 = distinct !{!28, !14, !24, !25, !26}
