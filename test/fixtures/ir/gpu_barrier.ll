; ModuleID = 'gpu_barrier.cu'
source_filename = "gpu_barrier.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

@_ZZ11stencil_badPKfPfiE1s = internal unnamed_addr addrspace(3) global [258 x float] undef, align 4
@_ZZ10stencil_okPKfPfiE1s = internal unnamed_addr addrspace(3) global [258 x float] undef, align 4

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z11stencil_badPKfPfi(ptr nocapture noundef readonly %in, ptr nocapture noundef writeonly %out, i32 noundef %n) local_unnamed_addr #0 !dbg !11 {
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
  %arrayidx = getelementptr inbounds float, ptr %in, i64 %idxprom, !dbg !28
  %3 = load float, ptr %arrayidx, align 4, !dbg !28, !tbaa !29
  %add4 = add i32 %2, 1, !dbg !33
  %idxprom5 = zext i32 %add4 to i64, !dbg !34
  %arrayidx6 = getelementptr inbounds [258 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ11stencil_badPKfPfiE1s to ptr), i64 0, i64 %idxprom5, !dbg !34
  store float %3, ptr %arrayidx6, align 4, !dbg !35, !tbaa !29
  tail call void @llvm.nvvm.barrier0(), !dbg !36
  %idxprom8 = zext i32 %2 to i64, !dbg !37
  %arrayidx9 = getelementptr inbounds [258 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ11stencil_badPKfPfiE1s to ptr), i64 0, i64 %idxprom8, !dbg !37
  %4 = load float, ptr %arrayidx9, align 4, !dbg !37, !tbaa !29
  %5 = load float, ptr %arrayidx6, align 4, !dbg !38, !tbaa !29
  %add14 = fadd contract float %4, %5, !dbg !39
  %add16 = add i32 %2, 2, !dbg !40
  %idxprom17 = zext i32 %add16 to i64, !dbg !41
  %arrayidx18 = getelementptr inbounds [258 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ11stencil_badPKfPfiE1s to ptr), i64 0, i64 %idxprom17, !dbg !41
  %6 = load float, ptr %arrayidx18, align 4, !dbg !41, !tbaa !29
  %add19 = fadd contract float %add14, %6, !dbg !42
  %arrayidx21 = getelementptr inbounds float, ptr %out, i64 %idxprom, !dbg !43
  store float %add19, ptr %arrayidx21, align 4, !dbg !44, !tbaa !29
  br label %if.end, !dbg !45

if.end:                                           ; preds = %if.then, %entry
  ret void, !dbg !46
}

; Function Attrs: convergent nocallback nounwind
declare void @llvm.nvvm.barrier0() #1

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z10stencil_okPKfPfi(ptr nocapture noundef readonly %in, ptr nocapture noundef writeonly %out, i32 noundef %n) local_unnamed_addr #0 !dbg !47 {
entry:
  %0 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !48
  %1 = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !50
  %mul = mul i32 %0, %1, !dbg !52
  %2 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !53
  %add = add i32 %mul, %2, !dbg !55
  %cmp = icmp slt i32 %add, %n, !dbg !56
  br i1 %cmp, label %if.then, label %if.end, !dbg !57

if.then:                                          ; preds = %entry
  %add4 = add i32 %2, 1, !dbg !58
  %idxprom5 = zext i32 %add4 to i64, !dbg !59
  %arrayidx6 = getelementptr inbounds [258 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ10stencil_okPKfPfiE1s to ptr), i64 0, i64 %idxprom5, !dbg !59
  %idxprom = sext i32 %add to i64, !dbg !60
  %arrayidx = getelementptr inbounds float, ptr %in, i64 %idxprom, !dbg !60
  %3 = load float, ptr %arrayidx, align 4, !dbg !60, !tbaa !29
  store float %3, ptr %arrayidx6, align 4, !dbg !61, !tbaa !29
  br label %if.end, !dbg !59

if.end:                                           ; preds = %if.then, %entry
  tail call void @llvm.nvvm.barrier0(), !dbg !62
  br i1 %cmp, label %if.then8, label %if.end24, !dbg !63

if.then8:                                         ; preds = %if.end
  %idxprom10 = zext i32 %2 to i64, !dbg !64
  %arrayidx11 = getelementptr inbounds [258 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ10stencil_okPKfPfiE1s to ptr), i64 0, i64 %idxprom10, !dbg !64
  %4 = load float, ptr %arrayidx11, align 4, !dbg !64, !tbaa !29
  %add13 = add i32 %2, 1, !dbg !65
  %idxprom14 = zext i32 %add13 to i64, !dbg !66
  %arrayidx15 = getelementptr inbounds [258 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ10stencil_okPKfPfiE1s to ptr), i64 0, i64 %idxprom14, !dbg !66
  %5 = load float, ptr %arrayidx15, align 4, !dbg !66, !tbaa !29
  %add16 = fadd contract float %4, %5, !dbg !67
  %add18 = add i32 %2, 2, !dbg !68
  %idxprom19 = zext i32 %add18 to i64, !dbg !69
  %arrayidx20 = getelementptr inbounds [258 x float], ptr addrspacecast (ptr addrspace(3) @_ZZ10stencil_okPKfPfiE1s to ptr), i64 0, i64 %idxprom19, !dbg !69
  %6 = load float, ptr %arrayidx20, align 4, !dbg !69, !tbaa !29
  %add21 = fadd contract float %add16, %6, !dbg !70
  %idxprom22 = sext i32 %add to i64, !dbg !71
  %arrayidx23 = getelementptr inbounds float, ptr %out, i64 %idxprom22, !dbg !71
  store float %add21, ptr %arrayidx23, align 4, !dbg !72, !tbaa !29
  br label %if.end24, !dbg !71

if.end24:                                         ; preds = %if.then8, %if.end
  ret void, !dbg !73
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.read.ptx.sreg.tid.x() #2

attributes #0 = { convergent mustprogress norecurse nounwind "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_70" "target-features"="+ptx42,+sm_70" }
attributes #1 = { convergent nocallback nounwind }
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
!7 = !DIFile(filename: "gpu_barrier.cu", directory: ".")
!8 = !{ptr @_Z11stencil_badPKfPfi, !"kernel", i32 1}
!9 = !{ptr @_Z10stencil_okPKfPfi, !"kernel", i32 1}
!10 = !{!"Homebrew clang version 15.0.7"}
!11 = distinct !DISubprogram(name: "stencil_bad", scope: !7, file: !7, line: 5, type: !12, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!12 = !DISubroutineType(types: !13)
!13 = !{}
!14 = !DILocation(line: 66, column: 3, scope: !15, inlinedAt: !17)
!15 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !16, file: !16, line: 66, type: !12, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!16 = !DIFile(filename: "/opt/homebrew/Cellar/llvm@15/15.0.7/lib/clang/15.0.7/include/__clang_cuda_builtin_vars.h", directory: "")
!17 = distinct !DILocation(line: 7, column: 11, scope: !11)
!18 = !DILocation(line: 79, column: 3, scope: !19, inlinedAt: !20)
!19 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !16, file: !16, line: 79, type: !12, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!20 = distinct !DILocation(line: 7, column: 24, scope: !11)
!21 = !DILocation(line: 7, column: 22, scope: !11)
!22 = !DILocation(line: 53, column: 3, scope: !23, inlinedAt: !24)
!23 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !16, file: !16, line: 53, type: !12, scopeLine: 53, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!24 = distinct !DILocation(line: 7, column: 37, scope: !11)
!25 = !DILocation(line: 7, column: 35, scope: !11)
!26 = !DILocation(line: 8, column: 9, scope: !11)
!27 = !DILocation(line: 8, column: 7, scope: !11)
!28 = !DILocation(line: 9, column: 26, scope: !11)
!29 = !{!30, !30, i64 0}
!30 = !{!"float", !31, i64 0}
!31 = !{!"omnipotent char", !32, i64 0}
!32 = !{!"Simple C++ TBAA"}
!33 = !DILocation(line: 9, column: 19, scope: !11)
!34 = !DILocation(line: 9, column: 5, scope: !11)
!35 = !DILocation(line: 9, column: 24, scope: !11)
!36 = !DILocation(line: 10, column: 5, scope: !11)
!37 = !DILocation(line: 11, column: 14, scope: !11)
!38 = !DILocation(line: 11, column: 31, scope: !11)
!39 = !DILocation(line: 11, column: 29, scope: !11)
!40 = !DILocation(line: 11, column: 66, scope: !11)
!41 = !DILocation(line: 11, column: 52, scope: !11)
!42 = !DILocation(line: 11, column: 50, scope: !11)
!43 = !DILocation(line: 11, column: 5, scope: !11)
!44 = !DILocation(line: 11, column: 12, scope: !11)
!45 = !DILocation(line: 12, column: 3, scope: !11)
!46 = !DILocation(line: 13, column: 1, scope: !11)
!47 = distinct !DISubprogram(name: "stencil_ok", scope: !7, file: !7, line: 16, type: !12, scopeLine: 16, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6, retainedNodes: !13)
!48 = !DILocation(line: 66, column: 3, scope: !15, inlinedAt: !49)
!49 = distinct !DILocation(line: 18, column: 11, scope: !47)
!50 = !DILocation(line: 79, column: 3, scope: !19, inlinedAt: !51)
!51 = distinct !DILocation(line: 18, column: 24, scope: !47)
!52 = !DILocation(line: 18, column: 22, scope: !47)
!53 = !DILocation(line: 53, column: 3, scope: !23, inlinedAt: !54)
!54 = distinct !DILocation(line: 18, column: 37, scope: !47)
!55 = !DILocation(line: 18, column: 35, scope: !47)
!56 = !DILocation(line: 19, column: 9, scope: !47)
!57 = !DILocation(line: 19, column: 7, scope: !47)
!58 = !DILocation(line: 20, column: 19, scope: !47)
!59 = !DILocation(line: 20, column: 5, scope: !47)
!60 = !DILocation(line: 20, column: 26, scope: !47)
!61 = !DILocation(line: 20, column: 24, scope: !47)
!62 = !DILocation(line: 21, column: 3, scope: !47)
!63 = !DILocation(line: 22, column: 7, scope: !47)
!64 = !DILocation(line: 23, column: 14, scope: !47)
!65 = !DILocation(line: 23, column: 45, scope: !47)
!66 = !DILocation(line: 23, column: 31, scope: !47)
!67 = !DILocation(line: 23, column: 29, scope: !47)
!68 = !DILocation(line: 23, column: 66, scope: !47)
!69 = !DILocation(line: 23, column: 52, scope: !47)
!70 = !DILocation(line: 23, column: 50, scope: !47)
!71 = !DILocation(line: 23, column: 5, scope: !47)
!72 = !DILocation(line: 23, column: 12, scope: !47)
!73 = !DILocation(line: 24, column: 1, scope: !47)
