; ModuleID = 'hip_strided.hip'
source_filename = "hip_strided.hip"
target datalayout = "e-p:64:64-p1:64:64-p2:32:32-p3:32:32-p4:64:64-p5:32:32-p6:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-v2048:2048-n32:64-S32-A5-G1-ni:7"
target triple = "amdgcn-amd-amdhsa"

; Function Attrs: argmemonly mustprogress nofree norecurse nosync nounwind willreturn
define protected amdgpu_kernel void @_Z12scale_columnPffi(ptr addrspace(1) nocapture noundef %m.coerce, float noundef %s, i32 noundef %n) local_unnamed_addr #0 !dbg !8 {
entry:
  %0 = tail call i32 @llvm.amdgcn.workgroup.id.x(), !dbg !11
  %mul = shl i32 %0, 8, !dbg !12
  %1 = tail call i32 @llvm.amdgcn.workitem.id.x(), !dbg !13, !range !14
  %add = add i32 %mul, %1, !dbg !15
  %cmp = icmp slt i32 %add, %n, !dbg !16
  br i1 %cmp, label %if.then, label %if.end, !dbg !17

if.then:                                          ; preds = %entry
  %mul2 = mul nsw i32 %add, %n, !dbg !18
  %idxprom = sext i32 %mul2 to i64, !dbg !19
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %m.coerce, i64 %idxprom
  %2 = load float, ptr addrspace(1) %arrayidx, align 4, !dbg !20, !tbaa !21, !amdgpu.noclobber !10
  %mul3 = fmul contract float %2, %s, !dbg !20
  store float %mul3, ptr addrspace(1) %arrayidx, align 4, !dbg !20, !tbaa !21
  br label %if.end, !dbg !19

if.end:                                           ; preds = %if.then, %entry
  ret void, !dbg !25
}

; Function Attrs: mustprogress nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.amdgcn.workgroup.id.x() #1

; Function Attrs: mustprogress nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.amdgcn.workitem.id.x() #1

; Function Attrs: argmemonly mustprogress nofree norecurse nosync nounwind willreturn
define protected amdgpu_kernel void @_Z9scale_rowPffi(ptr addrspace(1) nocapture noundef %m.coerce, float noundef %s, i32 noundef %n) local_unnamed_addr #0 !dbg !26 {
entry:
  %0 = tail call i32 @llvm.amdgcn.workgroup.id.x(), !dbg !27
  %mul = shl i32 %0, 8, !dbg !28
  %1 = tail call i32 @llvm.amdgcn.workitem.id.x(), !dbg !29, !range !14
  %add = add i32 %mul, %1, !dbg !30
  %cmp = icmp slt i32 %add, %n, !dbg !31
  br i1 %cmp, label %if.then, label %if.end, !dbg !32

if.then:                                          ; preds = %entry
  %idxprom = sext i32 %add to i64, !dbg !33
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %m.coerce, i64 %idxprom
  %2 = load float, ptr addrspace(1) %arrayidx, align 4, !dbg !34, !tbaa !21, !amdgpu.noclobber !10
  %mul2 = fmul contract float %2, %s, !dbg !34
  store float %mul2, ptr addrspace(1) %arrayidx, align 4, !dbg !34, !tbaa !21
  br label %if.end, !dbg !33

if.end:                                           ; preds = %if.then, %entry
  ret void, !dbg !35
}

attributes #0 = { argmemonly mustprogress nofree norecurse nosync nounwind willreturn "amdgpu-flat-work-group-size"="1,1024" "frame-pointer"="none" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx90a" "target-features"="+16-bit-insts,+ci-insts,+dl-insts,+dot1-insts,+dot2-insts,+dot3-insts,+dot4-insts,+dot5-insts,+dot6-insts,+dot7-insts,+dpp,+flat-address-space,+gfx8-insts,+gfx9-insts,+gfx90a-insts,+mai-insts,+s-memrealtime,+s-memtime-inst" "uniform-work-group-size"="true" }
attributes #1 = { mustprogress nofree nosync nounwind readnone speculatable willreturn }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.dbg.cu = !{!5}
!llvm.ident = !{!7}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 2]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 7, !"PIC Level", i32 1}
!5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_11, file: !6, producer: "Homebrew clang version 15.0.7", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly, splitDebugInlining: false, nameTableKind: None)
!6 = !DIFile(filename: "hip_strided.hip", directory: ".", checksumkind: CSK_MD5, checksum: "cb8f56a48276253b566ceaaf6ceafd0c")
!7 = !{!"Homebrew clang version 15.0.7"}
!8 = distinct !DISubprogram(name: "scale_column", scope: !6, file: !6, line: 5, type: !9, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !5, retainedNodes: !10)
!9 = !DISubroutineType(types: !10)
!10 = !{}
!11 = !DILocation(line: 6, column: 13, scope: !8)
!12 = !DILocation(line: 6, column: 47, scope: !8)
!13 = !DILocation(line: 7, column: 13, scope: !8)
!14 = !{i32 0, i32 1024}
!15 = !DILocation(line: 6, column: 53, scope: !8)
!16 = !DILocation(line: 8, column: 11, scope: !8)
!17 = !DILocation(line: 8, column: 7, scope: !8)
!18 = !DILocation(line: 9, column: 11, scope: !8)
!19 = !DILocation(line: 9, column: 5, scope: !8)
!20 = !DILocation(line: 9, column: 16, scope: !8)
!21 = !{!22, !22, i64 0}
!22 = !{!"float", !23, i64 0}
!23 = !{!"omnipotent char", !24, i64 0}
!24 = !{!"Simple C++ TBAA"}
!25 = !DILocation(line: 10, column: 1, scope: !8)
!26 = distinct !DISubprogram(name: "scale_row", scope: !6, file: !6, line: 12, type: !9, scopeLine: 12, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !5, retainedNodes: !10)
!27 = !DILocation(line: 13, column: 11, scope: !26)
!28 = !DILocation(line: 13, column: 45, scope: !26)
!29 = !DILocation(line: 14, column: 11, scope: !26)
!30 = !DILocation(line: 13, column: 51, scope: !26)
!31 = !DILocation(line: 15, column: 9, scope: !26)
!32 = !DILocation(line: 15, column: 7, scope: !26)
!33 = !DILocation(line: 16, column: 5, scope: !26)
!34 = !DILocation(line: 16, column: 10, scope: !26)
!35 = !DILocation(line: 17, column: 1, scope: !26)
