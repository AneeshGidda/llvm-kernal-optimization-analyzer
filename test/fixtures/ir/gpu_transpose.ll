; ModuleID = 'gpu_transpose.cu'
source_filename = "gpu_transpose.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

@_ZZ15transpose_tiledPKfPfiE4tile = internal unnamed_addr addrspace(3) global [32 x [32 x float]] undef, align 4
@_ZZ16transpose_paddedPKfPfiE4tile = internal unnamed_addr addrspace(3) global [32 x [33 x float]] undef, align 4

; Function Attrs: argmemonly mustprogress nofree norecurse nosync nounwind willreturn
define dso_local void @_Z15transpose_naivePKfPfi(ptr nocapture noundef readonly %in, ptr nocapture noundef writeonly %out, i32 noundef %n) local_unnamed_addr #0 !dbg !12 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !15
  %mul = shl i32 %0, 5, !dbg !19
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !20
  %add = add i32 %mul, %1, !dbg !23
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.y(), !dbg !24
  %mul3 = shl i32 %2, 5, !dbg !27
  %3 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.y(), !dbg !28
  %add5 = add i32 %mul3, %3, !dbg !31
  %mul6 = mul nsw i32 %add5, %n, !dbg !32
  %add7 = add nsw i32 %mul6, %add, !dbg !33
  %idxprom = sext i32 %add7 to i64, !dbg !34
  %arrayidx = getelementptr inbounds float, ptr %in, i64 %idxprom, !dbg !34
  %4 = load float, ptr %arrayidx, align 4, !dbg !34, !tbaa !35
  %mul8 = mul nsw i32 %add, %n, !dbg !39
  %add9 = add nsw i32 %mul8, %add5, !dbg !40
  %idxprom10 = sext i32 %add9 to i64, !dbg !41
  %arrayidx11 = getelementptr inbounds float, ptr %out, i64 %idxprom10, !dbg !41
  store float %4, ptr %arrayidx11, align 4, !dbg !42, !tbaa !35
  ret void, !dbg !43
}

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z15transpose_tiledPKfPfi(ptr nocapture noundef readonly %in, ptr nocapture noundef writeonly %out, i32 noundef %n) local_unnamed_addr #1 !dbg !44 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !45
  %mul = shl i32 %0, 5, !dbg !47
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !48
  %add = add i32 %mul, %1, !dbg !50
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.y(), !dbg !51
  %mul3 = shl i32 %2, 5, !dbg !53
  %3 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.y(), !dbg !54
  %add5 = add i32 %mul3, %3, !dbg !56
  %mul6 = mul nsw i32 %add5, %n, !dbg !57
  %add7 = add nsw i32 %add, %mul6, !dbg !58
  %idxprom = sext i32 %add7 to i64, !dbg !59
  %arrayidx = getelementptr inbounds float, ptr %in, i64 %idxprom, !dbg !59
  %4 = load float, ptr %arrayidx, align 4, !dbg !59, !tbaa !35
  %idxprom9 = zext i32 %3 to i64, !dbg !60
  %idxprom12 = zext i32 %1 to i64, !dbg !60
  %arrayidx13 = getelementptr inbounds [32 x [32 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ15transpose_tiledPKfPfiE4tile to ptr), i64 0, i64 %idxprom9, i64 %idxprom12, !dbg !60
  store float %4, ptr %arrayidx13, align 4, !dbg !61, !tbaa !35
  tail call void @llvm.nvvm.barrier0(), !dbg !62
  %add17 = add i32 %mul3, %1, !dbg !63
  %add21 = add i32 %mul, %3, !dbg !64
  %arrayidx27 = getelementptr inbounds [32 x [32 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ15transpose_tiledPKfPfiE4tile to ptr), i64 0, i64 %idxprom12, i64 %idxprom9, !dbg !65
  %5 = load float, ptr %arrayidx27, align 4, !dbg !65, !tbaa !35
  %mul28 = mul nsw i32 %add21, %n, !dbg !66
  %add29 = add nsw i32 %add17, %mul28, !dbg !67
  %idxprom30 = sext i32 %add29 to i64, !dbg !68
  %arrayidx31 = getelementptr inbounds float, ptr %out, i64 %idxprom30, !dbg !68
  store float %5, ptr %arrayidx31, align 4, !dbg !69, !tbaa !35
  ret void, !dbg !70
}

; Function Attrs: convergent nocallback nounwind
declare void @llvm.nvvm.barrier0() #2

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z16transpose_paddedPKfPfi(ptr nocapture noundef readonly %in, ptr nocapture noundef writeonly %out, i32 noundef %n) local_unnamed_addr #1 !dbg !71 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !72
  %mul = shl i32 %0, 5, !dbg !74
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !75
  %add = add i32 %mul, %1, !dbg !77
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.y(), !dbg !78
  %mul3 = shl i32 %2, 5, !dbg !80
  %3 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.y(), !dbg !81
  %add5 = add i32 %mul3, %3, !dbg !83
  %mul6 = mul nsw i32 %add5, %n, !dbg !84
  %add7 = add nsw i32 %add, %mul6, !dbg !85
  %idxprom = sext i32 %add7 to i64, !dbg !86
  %arrayidx = getelementptr inbounds float, ptr %in, i64 %idxprom, !dbg !86
  %4 = load float, ptr %arrayidx, align 4, !dbg !86, !tbaa !35
  %idxprom9 = zext i32 %3 to i64, !dbg !87
  %idxprom12 = zext i32 %1 to i64, !dbg !87
  %arrayidx13 = getelementptr inbounds [32 x [33 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ16transpose_paddedPKfPfiE4tile to ptr), i64 0, i64 %idxprom9, i64 %idxprom12, !dbg !87
  store float %4, ptr %arrayidx13, align 4, !dbg !88, !tbaa !35
  tail call void @llvm.nvvm.barrier0(), !dbg !89
  %add17 = add i32 %mul3, %1, !dbg !90
  %add21 = add i32 %mul, %3, !dbg !91
  %arrayidx27 = getelementptr inbounds [32 x [33 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ16transpose_paddedPKfPfiE4tile to ptr), i64 0, i64 %idxprom12, i64 %idxprom9, !dbg !92
  %5 = load float, ptr %arrayidx27, align 4, !dbg !92, !tbaa !35
  %mul28 = mul nsw i32 %add21, %n, !dbg !93
  %add29 = add nsw i32 %add17, %mul28, !dbg !94
  %idxprom30 = sext i32 %add29 to i64, !dbg !95
  %arrayidx31 = getelementptr inbounds float, ptr %out, i64 %idxprom30, !dbg !95
  store float %5, ptr %arrayidx31, align 4, !dbg !96, !tbaa !35
  ret void, !dbg !97
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.tid.x() #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.ctaid.y() #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.tid.y() #3

attributes #0 = { argmemonly mustprogress nofree norecurse nosync nounwind willreturn "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_70" "target-features"="+ptx42,+sm_70" }
attributes #1 = { convergent mustprogress norecurse nounwind "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_70" "target-features"="+ptx42,+sm_70" }
attributes #2 = { convergent nocallback nounwind }
attributes #3 = { mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5}
!llvm.dbg.cu = !{!6}
!nvvm.annotations = !{!8, !9, !10}
!llvm.ident = !{!11}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 2]}
!1 = !{i32 7, !"Dwarf Version", i32 2}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !7, producer: "Homebrew clang version 15.0.7", isOptimized: true, runtimeVersion: 0, emissionKind: DebugDirectivesOnly, splitDebugInlining: false, nameTableKind: None)
!7 = !DIFile(filename: "gpu_transpose.cu", directory: ".")
!8 = !{ptr @_Z15transpose_naivePKfPfi, !"kernel", i32 1}
!9 = !{ptr @_Z15transpose_tiledPKfPfi, !"kernel", i32 1}
!10 = !{ptr @_Z16transpose_paddedPKfPfi, !"kernel", i32 1}
!11 = !{!"Homebrew clang version 15.0.7"}
!12 = distinct !DISubprogram(name: "transpose_naive", scope: !7, file: !7, line: 6, type: !13, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !14)
!13 = !DISubroutineType(types: !14)
!14 = !{}
!15 = !DILocation(line: 66, column: 3, scope: !16, inlinedAt: !18)
!16 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !17, file: !17, line: 66, type: !13, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !14)
!17 = !DIFile(filename: "/opt/homebrew/Cellar/llvm@15/15.0.7/lib/clang/15.0.7/include/__clang_cuda_builtin_vars.h", directory: "")
!18 = distinct !DILocation(line: 7, column: 11, scope: !12)
!19 = !DILocation(line: 7, column: 22, scope: !12)
!20 = !DILocation(line: 53, column: 3, scope: !21, inlinedAt: !22)
!21 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !17, file: !17, line: 53, type: !13, scopeLine: 53, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !14)
!22 = distinct !DILocation(line: 7, column: 31, scope: !12)
!23 = !DILocation(line: 7, column: 29, scope: !12)
!24 = !DILocation(line: 67, column: 3, scope: !25, inlinedAt: !26)
!25 = distinct !DISubprogram(name: "__fetch_builtin_y", scope: !17, file: !17, line: 67, type: !13, scopeLine: 67, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !14)
!26 = distinct !DILocation(line: 8, column: 11, scope: !12)
!27 = !DILocation(line: 8, column: 22, scope: !12)
!28 = !DILocation(line: 54, column: 3, scope: !29, inlinedAt: !30)
!29 = distinct !DISubprogram(name: "__fetch_builtin_y", scope: !17, file: !17, line: 54, type: !13, scopeLine: 54, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !14)
!30 = distinct !DILocation(line: 8, column: 31, scope: !12)
!31 = !DILocation(line: 8, column: 29, scope: !12)
!32 = !DILocation(line: 9, column: 25, scope: !12)
!33 = !DILocation(line: 9, column: 29, scope: !12)
!34 = !DILocation(line: 9, column: 20, scope: !12)
!35 = !{!36, !36, i64 0}
!36 = !{!"float", !37, i64 0}
!37 = !{!"omnipotent char", !38, i64 0}
!38 = !{!"Simple C++ TBAA"}
!39 = !DILocation(line: 9, column: 9, scope: !12)
!40 = !DILocation(line: 9, column: 13, scope: !12)
!41 = !DILocation(line: 9, column: 3, scope: !12)
!42 = !DILocation(line: 9, column: 18, scope: !12)
!43 = !DILocation(line: 10, column: 1, scope: !12)
!44 = distinct !DISubprogram(name: "transpose_tiled", scope: !7, file: !7, line: 14, type: !13, scopeLine: 14, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !14)
!45 = !DILocation(line: 66, column: 3, scope: !16, inlinedAt: !46)
!46 = distinct !DILocation(line: 16, column: 11, scope: !44)
!47 = !DILocation(line: 16, column: 22, scope: !44)
!48 = !DILocation(line: 53, column: 3, scope: !21, inlinedAt: !49)
!49 = distinct !DILocation(line: 16, column: 31, scope: !44)
!50 = !DILocation(line: 16, column: 29, scope: !44)
!51 = !DILocation(line: 67, column: 3, scope: !25, inlinedAt: !52)
!52 = distinct !DILocation(line: 17, column: 11, scope: !44)
!53 = !DILocation(line: 17, column: 22, scope: !44)
!54 = !DILocation(line: 54, column: 3, scope: !29, inlinedAt: !55)
!55 = distinct !DILocation(line: 17, column: 31, scope: !44)
!56 = !DILocation(line: 17, column: 29, scope: !44)
!57 = !DILocation(line: 18, column: 41, scope: !44)
!58 = !DILocation(line: 18, column: 45, scope: !44)
!59 = !DILocation(line: 18, column: 36, scope: !44)
!60 = !DILocation(line: 18, column: 3, scope: !44)
!61 = !DILocation(line: 18, column: 34, scope: !44)
!62 = !DILocation(line: 19, column: 3, scope: !44)
!63 = !DILocation(line: 20, column: 25, scope: !44)
!64 = !DILocation(line: 21, column: 25, scope: !44)
!65 = !DILocation(line: 22, column: 20, scope: !44)
!66 = !DILocation(line: 22, column: 9, scope: !44)
!67 = !DILocation(line: 22, column: 13, scope: !44)
!68 = !DILocation(line: 22, column: 3, scope: !44)
!69 = !DILocation(line: 22, column: 18, scope: !44)
!70 = !DILocation(line: 23, column: 1, scope: !44)
!71 = distinct !DISubprogram(name: "transpose_padded", scope: !7, file: !7, line: 26, type: !13, scopeLine: 26, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !14)
!72 = !DILocation(line: 66, column: 3, scope: !16, inlinedAt: !73)
!73 = distinct !DILocation(line: 28, column: 11, scope: !71)
!74 = !DILocation(line: 28, column: 22, scope: !71)
!75 = !DILocation(line: 53, column: 3, scope: !21, inlinedAt: !76)
!76 = distinct !DILocation(line: 28, column: 31, scope: !71)
!77 = !DILocation(line: 28, column: 29, scope: !71)
!78 = !DILocation(line: 67, column: 3, scope: !25, inlinedAt: !79)
!79 = distinct !DILocation(line: 29, column: 11, scope: !71)
!80 = !DILocation(line: 29, column: 22, scope: !71)
!81 = !DILocation(line: 54, column: 3, scope: !29, inlinedAt: !82)
!82 = distinct !DILocation(line: 29, column: 31, scope: !71)
!83 = !DILocation(line: 29, column: 29, scope: !71)
!84 = !DILocation(line: 30, column: 41, scope: !71)
!85 = !DILocation(line: 30, column: 45, scope: !71)
!86 = !DILocation(line: 30, column: 36, scope: !71)
!87 = !DILocation(line: 30, column: 3, scope: !71)
!88 = !DILocation(line: 30, column: 34, scope: !71)
!89 = !DILocation(line: 31, column: 3, scope: !71)
!90 = !DILocation(line: 32, column: 25, scope: !71)
!91 = !DILocation(line: 33, column: 25, scope: !71)
!92 = !DILocation(line: 34, column: 20, scope: !71)
!93 = !DILocation(line: 34, column: 9, scope: !71)
!94 = !DILocation(line: 34, column: 13, scope: !71)
!95 = !DILocation(line: 34, column: 3, scope: !71)
!96 = !DILocation(line: 34, column: 18, scope: !71)
!97 = !DILocation(line: 35, column: 1, scope: !71)
