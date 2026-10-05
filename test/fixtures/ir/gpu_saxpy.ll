; ModuleID = 'gpu_saxpy.cu'
source_filename = "gpu_saxpy.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

; Function Attrs: argmemonly mustprogress nofree norecurse nosync nounwind willreturn
define dso_local void @_Z5saxpyfPKfPfi(float noundef %a, ptr nocapture noundef readonly %x, ptr nocapture noundef %y, i32 noundef %n) local_unnamed_addr #0 !dbg !11 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !14
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !18
  %mul = mul i32 %0, %1, !dbg !21
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !22
  %add = add i32 %mul, %2, !dbg !25
  %cmp = icmp slt i32 %add, %n, !dbg !26
  br i1 %cmp, label %if.then, label %if.end, !dbg !27

if.then:                                          ; preds = %entry
  %idxprom = sext i32 %add to i64, !dbg !28
  %arrayidx = getelementptr inbounds float, ptr %x, i64 %idxprom, !dbg !28
  %3 = load float, ptr %arrayidx, align 4, !dbg !28, !tbaa !29
  %mul3 = fmul contract float %3, %a, !dbg !33
  %arrayidx5 = getelementptr inbounds float, ptr %y, i64 %idxprom, !dbg !34
  %4 = load float, ptr %arrayidx5, align 4, !dbg !34, !tbaa !29
  %add6 = fadd contract float %mul3, %4, !dbg !35
  store float %add6, ptr %arrayidx5, align 4, !dbg !36, !tbaa !29
  br label %if.end, !dbg !37

if.end:                                           ; preds = %if.then, %entry
  ret void, !dbg !38
}

; Function Attrs: argmemonly mustprogress nofree norecurse nosync nounwind
define dso_local void @_Z17saxpy_grid_stridefPKfPfi(float noundef %a, ptr nocapture noundef readonly %x, ptr nocapture noundef %y, i32 noundef %n) local_unnamed_addr #1 !dbg !39 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !40
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !42
  %mul = mul i32 %0, %1, !dbg !44
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !45
  %add = add i32 %mul, %2, !dbg !47
  %cmp18 = icmp slt i32 %add, %n, !dbg !48
  br i1 %cmp18, label %for.body.lr.ph, label %for.cond.cleanup, !dbg !49

for.body.lr.ph:                                   ; preds = %entry
  %3 = tail call i32 @llvm.nvvm.read.ptx.sreg.nctaid.x(), !dbg !50
  %mul11 = mul i32 %1, %3
  br label %for.body, !dbg !49

for.cond.cleanup:                                 ; preds = %for.body, %entry
  ret void, !dbg !51

for.body:                                         ; preds = %for.body.lr.ph, %for.body
  %i.019 = phi i32 [ %add, %for.body.lr.ph ], [ %add12, %for.body ]
  %idxprom = sext i32 %i.019 to i64, !dbg !52
  %arrayidx = getelementptr inbounds float, ptr %x, i64 %idxprom, !dbg !52
  %4 = load float, ptr %arrayidx, align 4, !dbg !52, !tbaa !29
  %mul3 = fmul contract float %4, %a, !dbg !53
  %arrayidx5 = getelementptr inbounds float, ptr %y, i64 %idxprom, !dbg !54
  %5 = load float, ptr %arrayidx5, align 4, !dbg !54, !tbaa !29
  %add6 = fadd contract float %mul3, %5, !dbg !55
  store float %add6, ptr %arrayidx5, align 4, !dbg !56, !tbaa !29
  %add12 = add i32 %i.019, %mul11, !dbg !57
  %cmp = icmp slt i32 %add12, %n, !dbg !48
  br i1 %cmp, label %for.body, label %for.cond.cleanup, !dbg !49, !llvm.loop !58
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.tid.x() #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.nctaid.x() #2

attributes #0 = { argmemonly mustprogress nofree norecurse nosync nounwind willreturn "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_70" "target-features"="+ptx42,+sm_70" }
attributes #1 = { argmemonly mustprogress nofree norecurse nosync nounwind "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_70" "target-features"="+ptx42,+sm_70" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5}
!llvm.dbg.cu = !{!6}
!nvvm.annotations = !{!8, !9}
!llvm.ident = !{!10}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 2]}
!1 = !{i32 7, !"Dwarf Version", i32 2}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !7, producer: "Homebrew clang version 15.0.7", isOptimized: true, runtimeVersion: 0, emissionKind: DebugDirectivesOnly, splitDebugInlining: false, nameTableKind: None)
!7 = !DIFile(filename: "gpu_saxpy.cu", directory: ".")
!8 = !{ptr @_Z5saxpyfPKfPfi, !"kernel", i32 1}
!9 = !{ptr @_Z17saxpy_grid_stridefPKfPfi, !"kernel", i32 1}
!10 = !{!"Homebrew clang version 15.0.7"}
!11 = distinct !DISubprogram(name: "saxpy", scope: !7, file: !7, line: 5, type: !12, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!12 = !DISubroutineType(types: !13)
!13 = !{}
!14 = !DILocation(line: 66, column: 3, scope: !15, inlinedAt: !17)
!15 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !16, file: !16, line: 66, type: !12, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!16 = !DIFile(filename: "/opt/homebrew/Cellar/llvm@15/15.0.7/lib/clang/15.0.7/include/__clang_cuda_builtin_vars.h", directory: "")
!17 = distinct !DILocation(line: 6, column: 11, scope: !11)
!18 = !DILocation(line: 79, column: 3, scope: !19, inlinedAt: !20)
!19 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !16, file: !16, line: 79, type: !12, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!20 = distinct !DILocation(line: 6, column: 24, scope: !11)
!21 = !DILocation(line: 6, column: 22, scope: !11)
!22 = !DILocation(line: 53, column: 3, scope: !23, inlinedAt: !24)
!23 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !16, file: !16, line: 53, type: !12, scopeLine: 53, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!24 = distinct !DILocation(line: 6, column: 37, scope: !11)
!25 = !DILocation(line: 6, column: 35, scope: !11)
!26 = !DILocation(line: 7, column: 9, scope: !11)
!27 = !DILocation(line: 7, column: 7, scope: !11)
!28 = !DILocation(line: 8, column: 16, scope: !11)
!29 = !{!30, !30, i64 0}
!30 = !{!"float", !31, i64 0}
!31 = !{!"omnipotent char", !32, i64 0}
!32 = !{!"Simple C++ TBAA"}
!33 = !DILocation(line: 8, column: 14, scope: !11)
!34 = !DILocation(line: 8, column: 23, scope: !11)
!35 = !DILocation(line: 8, column: 21, scope: !11)
!36 = !DILocation(line: 8, column: 10, scope: !11)
!37 = !DILocation(line: 8, column: 5, scope: !11)
!38 = !DILocation(line: 9, column: 1, scope: !11)
!39 = distinct !DISubprogram(name: "saxpy_grid_stride", scope: !7, file: !7, line: 12, type: !12, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!40 = !DILocation(line: 66, column: 3, scope: !15, inlinedAt: !41)
!41 = distinct !DILocation(line: 13, column: 16, scope: !39)
!42 = !DILocation(line: 79, column: 3, scope: !19, inlinedAt: !43)
!43 = distinct !DILocation(line: 13, column: 29, scope: !39)
!44 = !DILocation(line: 13, column: 27, scope: !39)
!45 = !DILocation(line: 53, column: 3, scope: !23, inlinedAt: !46)
!46 = distinct !DILocation(line: 13, column: 42, scope: !39)
!47 = !DILocation(line: 13, column: 40, scope: !39)
!48 = !DILocation(line: 13, column: 57, scope: !39)
!49 = !DILocation(line: 13, column: 3, scope: !39)
!50 = !DILocation(line: 0, scope: !39)
!51 = !DILocation(line: 16, column: 1, scope: !39)
!52 = !DILocation(line: 15, column: 16, scope: !39)
!53 = !DILocation(line: 15, column: 14, scope: !39)
!54 = !DILocation(line: 15, column: 23, scope: !39)
!55 = !DILocation(line: 15, column: 21, scope: !39)
!56 = !DILocation(line: 15, column: 10, scope: !39)
!57 = !DILocation(line: 14, column: 10, scope: !39)
!58 = distinct !{!58, !49, !59, !60}
!59 = !DILocation(line: 15, column: 26, scope: !39)
!60 = !{!"llvm.loop.mustprogress"}
