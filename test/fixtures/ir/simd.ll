; ModuleID = 'simd.c'
source_filename = "simd.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree norecurse nosync nounwind ssp uwtable
define void @add_neon(ptr noalias nocapture noundef %y, ptr noalias nocapture noundef readonly %x, i32 noundef %n) local_unnamed_addr #0 !dbg !10 {
entry:
  %cmp.not13 = icmp slt i32 %n, 4, !dbg !13
  br i1 %cmp.not13, label %for.cond.cleanup, label %for.body.preheader, !dbg !14

for.body.preheader:                               ; preds = %entry
  %0 = zext i32 %n to i64, !dbg !14
  br label %for.body, !dbg !14

for.cond.cleanup:                                 ; preds = %for.body, %entry
  ret void, !dbg !15

for.body:                                         ; preds = %for.body.preheader, %for.body
  %indvars.iv16 = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next17, %for.body ]
  %indvars.iv = phi i64 [ 4, %for.body.preheader ], [ %indvars.iv.next, %for.body ]
  %indvars.iv.next17 = add nuw nsw i64 %indvars.iv16, 4
  %add.ptr = getelementptr inbounds float, ptr %y, i64 %indvars.iv16, !dbg !16
  %1 = load <4 x float>, ptr %add.ptr, align 4, !dbg !16
  %add.ptr3 = getelementptr inbounds float, ptr %x, i64 %indvars.iv16, !dbg !16
  %2 = load <4 x float>, ptr %add.ptr3, align 4, !dbg !16
  %add.i = fadd <4 x float> %1, %2, !dbg !16
  store <4 x float> %add.i, ptr %add.ptr, align 4, !dbg !16
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 4, !dbg !17
  %cmp.not = icmp ugt i64 %indvars.iv.next, %0, !dbg !13
  br i1 %cmp.not, label %for.cond.cleanup, label %for.body, !dbg !14, !llvm.loop !18
}

; Function Attrs: argmemonly nofree norecurse nosync nounwind ssp uwtable
define void @scale_disabled(ptr noalias nocapture noundef writeonly %y, ptr noalias nocapture noundef readonly %x, i32 noundef %n) local_unnamed_addr #1 !dbg !20 {
entry:
  %cmp6 = icmp sgt i32 %n, 0, !dbg !21
  br i1 %cmp6, label %for.body.preheader, label %for.cond.cleanup, !dbg !22

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !21
  %min.iters.check = icmp eq i32 %n, 1, !dbg !22
  br i1 %min.iters.check, label %for.body.preheader10, label %vector.ph, !dbg !22

vector.ph:                                        ; preds = %for.body.preheader
  %n.vec = and i64 %wide.trip.count, 4294967294, !dbg !22
  br label %vector.body, !dbg !22

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ], !dbg !23
  %0 = getelementptr inbounds float, ptr %x, i64 %index, !dbg !24
  %1 = getelementptr inbounds float, ptr %y, i64 %index, !dbg !25
  %2 = load <2 x float>, ptr %0, align 4, !dbg !24, !tbaa !26
  %3 = fmul <2 x float> %2, <float 2.000000e+00, float 2.000000e+00>, !dbg !30
  store <2 x float> %3, ptr %1, align 4, !dbg !31, !tbaa !26
  %index.next = add nuw i64 %index, 2, !dbg !23
  %4 = icmp eq i64 %index.next, %n.vec, !dbg !23
  br i1 %4, label %middle.block, label %vector.body, !dbg !23, !llvm.loop !32

middle.block:                                     ; preds = %vector.body
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count, !dbg !22
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader10, !dbg !22

for.body.preheader10:                             ; preds = %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  br label %for.body, !dbg !22

for.cond.cleanup:                                 ; preds = %for.body, %middle.block, %entry
  ret void, !dbg !35

for.body:                                         ; preds = %for.body.preheader10, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ %indvars.iv.ph, %for.body.preheader10 ]
  %arrayidx = getelementptr inbounds float, ptr %x, i64 %indvars.iv, !dbg !24
  %5 = load float, ptr %arrayidx, align 4, !dbg !24, !tbaa !26
  %mul = fmul float %5, 2.000000e+00, !dbg !30
  %arrayidx2 = getelementptr inbounds float, ptr %y, i64 %indvars.iv, !dbg !25
  store float %mul, ptr %arrayidx2, align 4, !dbg !31, !tbaa !26
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !23
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !21
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !22, !llvm.loop !36
}

; Function Attrs: argmemonly nofree norecurse nosync nounwind ssp uwtable
define void @rows(ptr noalias nocapture noundef writeonly %out, ptr noalias nocapture noundef readonly %in, i32 noundef %n) local_unnamed_addr #1 !dbg !37 {
entry:
  %cmp20 = icmp sgt i32 %n, 0, !dbg !38
  br i1 %cmp20, label %for.cond1.preheader.preheader, label %for.cond.cleanup, !dbg !39

for.cond1.preheader.preheader:                    ; preds = %entry
  %wide.trip.count = zext i32 %n to i64, !dbg !38
  br label %for.cond1.preheader, !dbg !39

for.cond1.preheader:                              ; preds = %for.cond1.preheader.preheader, %for.cond1.preheader
  %indvars.iv24 = phi i64 [ 0, %for.cond1.preheader.preheader ], [ %indvars.iv.next25, %for.cond1.preheader ]
  %0 = shl nsw i64 %indvars.iv24, 6
  %1 = getelementptr inbounds float, ptr %in, i64 %0, !dbg !40
  %wide.load = load <4 x float>, ptr %1, align 4, !dbg !40, !tbaa !26
  %2 = fmul <4 x float> %wide.load, <float 3.000000e+00, float 3.000000e+00, float 3.000000e+00, float 3.000000e+00>, !dbg !41
  %3 = getelementptr inbounds float, ptr %out, i64 %0, !dbg !42
  store <4 x float> %2, ptr %3, align 4, !dbg !43, !tbaa !26
  %4 = or i64 %0, 4, !dbg !44
  %5 = getelementptr inbounds float, ptr %in, i64 %4, !dbg !40
  %wide.load.1 = load <4 x float>, ptr %5, align 4, !dbg !40, !tbaa !26
  %6 = fmul <4 x float> %wide.load.1, <float 3.000000e+00, float 3.000000e+00, float 3.000000e+00, float 3.000000e+00>, !dbg !41
  %7 = getelementptr inbounds float, ptr %out, i64 %4, !dbg !42
  store <4 x float> %6, ptr %7, align 4, !dbg !43, !tbaa !26
  %8 = or i64 %0, 8, !dbg !44
  %9 = getelementptr inbounds float, ptr %in, i64 %8, !dbg !40
  %wide.load.2 = load <4 x float>, ptr %9, align 4, !dbg !40, !tbaa !26
  %10 = fmul <4 x float> %wide.load.2, <float 3.000000e+00, float 3.000000e+00, float 3.000000e+00, float 3.000000e+00>, !dbg !41
  %11 = getelementptr inbounds float, ptr %out, i64 %8, !dbg !42
  store <4 x float> %10, ptr %11, align 4, !dbg !43, !tbaa !26
  %12 = or i64 %0, 12, !dbg !44
  %13 = getelementptr inbounds float, ptr %in, i64 %12, !dbg !40
  %wide.load.3 = load <4 x float>, ptr %13, align 4, !dbg !40, !tbaa !26
  %14 = fmul <4 x float> %wide.load.3, <float 3.000000e+00, float 3.000000e+00, float 3.000000e+00, float 3.000000e+00>, !dbg !41
  %15 = getelementptr inbounds float, ptr %out, i64 %12, !dbg !42
  store <4 x float> %14, ptr %15, align 4, !dbg !43, !tbaa !26
  %16 = or i64 %0, 16, !dbg !44
  %17 = getelementptr inbounds float, ptr %in, i64 %16, !dbg !40
  %wide.load.4 = load <4 x float>, ptr %17, align 4, !dbg !40, !tbaa !26
  %18 = fmul <4 x float> %wide.load.4, <float 3.000000e+00, float 3.000000e+00, float 3.000000e+00, float 3.000000e+00>, !dbg !41
  %19 = getelementptr inbounds float, ptr %out, i64 %16, !dbg !42
  store <4 x float> %18, ptr %19, align 4, !dbg !43, !tbaa !26
  %20 = or i64 %0, 20, !dbg !44
  %21 = getelementptr inbounds float, ptr %in, i64 %20, !dbg !40
  %wide.load.5 = load <4 x float>, ptr %21, align 4, !dbg !40, !tbaa !26
  %22 = fmul <4 x float> %wide.load.5, <float 3.000000e+00, float 3.000000e+00, float 3.000000e+00, float 3.000000e+00>, !dbg !41
  %23 = getelementptr inbounds float, ptr %out, i64 %20, !dbg !42
  store <4 x float> %22, ptr %23, align 4, !dbg !43, !tbaa !26
  %24 = or i64 %0, 24, !dbg !44
  %25 = getelementptr inbounds float, ptr %in, i64 %24, !dbg !40
  %wide.load.6 = load <4 x float>, ptr %25, align 4, !dbg !40, !tbaa !26
  %26 = fmul <4 x float> %wide.load.6, <float 3.000000e+00, float 3.000000e+00, float 3.000000e+00, float 3.000000e+00>, !dbg !41
  %27 = getelementptr inbounds float, ptr %out, i64 %24, !dbg !42
  store <4 x float> %26, ptr %27, align 4, !dbg !43, !tbaa !26
  %28 = or i64 %0, 28, !dbg !44
  %29 = getelementptr inbounds float, ptr %in, i64 %28, !dbg !40
  %wide.load.7 = load <4 x float>, ptr %29, align 4, !dbg !40, !tbaa !26
  %30 = fmul <4 x float> %wide.load.7, <float 3.000000e+00, float 3.000000e+00, float 3.000000e+00, float 3.000000e+00>, !dbg !41
  %31 = getelementptr inbounds float, ptr %out, i64 %28, !dbg !42
  store <4 x float> %30, ptr %31, align 4, !dbg !43, !tbaa !26
  %32 = or i64 %0, 32, !dbg !44
  %33 = getelementptr inbounds float, ptr %in, i64 %32, !dbg !40
  %wide.load.8 = load <4 x float>, ptr %33, align 4, !dbg !40, !tbaa !26
  %34 = fmul <4 x float> %wide.load.8, <float 3.000000e+00, float 3.000000e+00, float 3.000000e+00, float 3.000000e+00>, !dbg !41
  %35 = getelementptr inbounds float, ptr %out, i64 %32, !dbg !42
  store <4 x float> %34, ptr %35, align 4, !dbg !43, !tbaa !26
  %36 = or i64 %0, 36, !dbg !44
  %37 = getelementptr inbounds float, ptr %in, i64 %36, !dbg !40
  %wide.load.9 = load <4 x float>, ptr %37, align 4, !dbg !40, !tbaa !26
  %38 = fmul <4 x float> %wide.load.9, <float 3.000000e+00, float 3.000000e+00, float 3.000000e+00, float 3.000000e+00>, !dbg !41
  %39 = getelementptr inbounds float, ptr %out, i64 %36, !dbg !42
  store <4 x float> %38, ptr %39, align 4, !dbg !43, !tbaa !26
  %40 = or i64 %0, 40, !dbg !44
  %41 = getelementptr inbounds float, ptr %in, i64 %40, !dbg !40
  %wide.load.10 = load <4 x float>, ptr %41, align 4, !dbg !40, !tbaa !26
  %42 = fmul <4 x float> %wide.load.10, <float 3.000000e+00, float 3.000000e+00, float 3.000000e+00, float 3.000000e+00>, !dbg !41
  %43 = getelementptr inbounds float, ptr %out, i64 %40, !dbg !42
  store <4 x float> %42, ptr %43, align 4, !dbg !43, !tbaa !26
  %44 = or i64 %0, 44, !dbg !44
  %45 = getelementptr inbounds float, ptr %in, i64 %44, !dbg !40
  %wide.load.11 = load <4 x float>, ptr %45, align 4, !dbg !40, !tbaa !26
  %46 = fmul <4 x float> %wide.load.11, <float 3.000000e+00, float 3.000000e+00, float 3.000000e+00, float 3.000000e+00>, !dbg !41
  %47 = getelementptr inbounds float, ptr %out, i64 %44, !dbg !42
  store <4 x float> %46, ptr %47, align 4, !dbg !43, !tbaa !26
  %48 = or i64 %0, 48, !dbg !44
  %49 = getelementptr inbounds float, ptr %in, i64 %48, !dbg !40
  %wide.load.12 = load <4 x float>, ptr %49, align 4, !dbg !40, !tbaa !26
  %50 = fmul <4 x float> %wide.load.12, <float 3.000000e+00, float 3.000000e+00, float 3.000000e+00, float 3.000000e+00>, !dbg !41
  %51 = getelementptr inbounds float, ptr %out, i64 %48, !dbg !42
  store <4 x float> %50, ptr %51, align 4, !dbg !43, !tbaa !26
  %52 = or i64 %0, 52, !dbg !44
  %53 = getelementptr inbounds float, ptr %in, i64 %52, !dbg !40
  %wide.load.13 = load <4 x float>, ptr %53, align 4, !dbg !40, !tbaa !26
  %54 = fmul <4 x float> %wide.load.13, <float 3.000000e+00, float 3.000000e+00, float 3.000000e+00, float 3.000000e+00>, !dbg !41
  %55 = getelementptr inbounds float, ptr %out, i64 %52, !dbg !42
  store <4 x float> %54, ptr %55, align 4, !dbg !43, !tbaa !26
  %56 = or i64 %0, 56, !dbg !44
  %57 = getelementptr inbounds float, ptr %in, i64 %56, !dbg !40
  %wide.load.14 = load <4 x float>, ptr %57, align 4, !dbg !40, !tbaa !26
  %58 = fmul <4 x float> %wide.load.14, <float 3.000000e+00, float 3.000000e+00, float 3.000000e+00, float 3.000000e+00>, !dbg !41
  %59 = getelementptr inbounds float, ptr %out, i64 %56, !dbg !42
  store <4 x float> %58, ptr %59, align 4, !dbg !43, !tbaa !26
  %60 = or i64 %0, 60, !dbg !44
  %61 = getelementptr inbounds float, ptr %in, i64 %60, !dbg !40
  %wide.load.15 = load <4 x float>, ptr %61, align 4, !dbg !40, !tbaa !26
  %62 = fmul <4 x float> %wide.load.15, <float 3.000000e+00, float 3.000000e+00, float 3.000000e+00, float 3.000000e+00>, !dbg !41
  %63 = getelementptr inbounds float, ptr %out, i64 %60, !dbg !42
  store <4 x float> %62, ptr %63, align 4, !dbg !43, !tbaa !26
  %indvars.iv.next25 = add nuw nsw i64 %indvars.iv24, 1, !dbg !45
  %exitcond28.not = icmp eq i64 %indvars.iv.next25, %wide.trip.count, !dbg !38
  br i1 %exitcond28.not, label %for.cond.cleanup, label %for.cond1.preheader, !dbg !39, !llvm.loop !46

for.cond.cleanup:                                 ; preds = %for.cond1.preheader, %entry
  ret void, !dbg !48
}

attributes #0 = { argmemonly nofree norecurse nosync nounwind ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="128" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #1 = { argmemonly nofree norecurse nosync nounwind ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }

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
!8 = !DIFile(filename: "simd.c", directory: ".")
!9 = !{!"Homebrew clang version 15.0.7"}
!10 = distinct !DISubprogram(name: "add_neon", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!11 = !DISubroutineType(types: !12)
!12 = !{}
!13 = !DILocation(line: 5, column: 25, scope: !10)
!14 = !DILocation(line: 5, column: 3, scope: !10)
!15 = !DILocation(line: 7, column: 1, scope: !10)
!16 = !DILocation(line: 6, column: 5, scope: !10)
!17 = !DILocation(line: 5, column: 21, scope: !10)
!18 = distinct !{!18, !14, !16, !19}
!19 = !{!"llvm.loop.mustprogress"}
!20 = distinct !DISubprogram(name: "scale_disabled", scope: !8, file: !8, line: 11, type: !11, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!21 = !DILocation(line: 13, column: 21, scope: !20)
!22 = !DILocation(line: 13, column: 3, scope: !20)
!23 = !DILocation(line: 13, column: 26, scope: !20)
!24 = !DILocation(line: 14, column: 19, scope: !20)
!25 = !DILocation(line: 14, column: 5, scope: !20)
!26 = !{!27, !27, i64 0}
!27 = !{!"float", !28, i64 0}
!28 = !{!"omnipotent char", !29, i64 0}
!29 = !{!"Simple C/C++ TBAA"}
!30 = !DILocation(line: 14, column: 17, scope: !20)
!31 = !DILocation(line: 14, column: 10, scope: !20)
!32 = distinct !{!32, !22, !33, !19, !34}
!33 = !DILocation(line: 14, column: 22, scope: !20)
!34 = !{!"llvm.loop.isvectorized", i32 1}
!35 = !DILocation(line: 15, column: 1, scope: !20)
!36 = distinct !{!36, !22, !33, !19, !34}
!37 = distinct !DISubprogram(name: "rows", scope: !8, file: !8, line: 19, type: !11, scopeLine: 19, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !12)
!38 = !DILocation(line: 20, column: 21, scope: !37)
!39 = !DILocation(line: 20, column: 3, scope: !37)
!40 = !DILocation(line: 22, column: 25, scope: !37)
!41 = !DILocation(line: 22, column: 40, scope: !37)
!42 = !DILocation(line: 22, column: 7, scope: !37)
!43 = !DILocation(line: 22, column: 23, scope: !37)
!44 = !DILocation(line: 22, column: 35, scope: !37)
!45 = !DILocation(line: 20, column: 26, scope: !37)
!46 = distinct !{!46, !39, !47, !19}
!47 = !DILocation(line: 22, column: 42, scope: !37)
!48 = !DILocation(line: 23, column: 1, scope: !37)
