; ModuleID = 'saxpy.c'
source_filename = "saxpy.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx13.0.0"

; Function Attrs: argmemonly nofree nosync nounwind ssp uwtable
define void @saxpy(float noundef %a, ptr nocapture noundef readonly %x, ptr nocapture noundef %y, i32 noundef %n) local_unnamed_addr #0 {
entry:
  %cmp10 = icmp sgt i32 %n, 0
  br i1 %cmp10, label %for.body.preheader, label %for.cond.cleanup

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64
  %min.iters.check = icmp ult i32 %n, 8
  br i1 %min.iters.check, label %for.body.preheader19, label %vector.memcheck

vector.memcheck:                                  ; preds = %for.body.preheader
  %0 = shl nuw nsw i64 %wide.trip.count, 2
  %uglygep = getelementptr i8, ptr %y, i64 %0
  %uglygep13 = getelementptr i8, ptr %x, i64 %0
  %bound0 = icmp ugt ptr %uglygep13, %y
  %bound1 = icmp ugt ptr %uglygep, %x
  %found.conflict = and i1 %bound0, %bound1
  br i1 %found.conflict, label %for.body.preheader19, label %vector.ph

vector.ph:                                        ; preds = %vector.memcheck
  %n.vec = and i64 %wide.trip.count, 4294967288
  %broadcast.splatinsert = insertelement <4 x float> poison, float %a, i64 0
  %broadcast.splat = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <4 x i32> zeroinitializer
  %broadcast.splatinsert17 = insertelement <4 x float> poison, float %a, i64 0
  %broadcast.splat18 = shufflevector <4 x float> %broadcast.splatinsert17, <4 x float> poison, <4 x i32> zeroinitializer
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %1 = getelementptr inbounds float, ptr %x, i64 %index
  %wide.load = load <4 x float>, ptr %1, align 4, !tbaa !5, !alias.scope !9
  %2 = getelementptr inbounds float, ptr %1, i64 4
  %wide.load14 = load <4 x float>, ptr %2, align 4, !tbaa !5, !alias.scope !9
  %3 = getelementptr inbounds float, ptr %y, i64 %index
  %wide.load15 = load <4 x float>, ptr %3, align 4, !tbaa !5, !alias.scope !12, !noalias !9
  %4 = getelementptr inbounds float, ptr %3, i64 4
  %wide.load16 = load <4 x float>, ptr %4, align 4, !tbaa !5, !alias.scope !12, !noalias !9
  %5 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load, <4 x float> %wide.load15)
  %6 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat18, <4 x float> %wide.load14, <4 x float> %wide.load16)
  store <4 x float> %5, ptr %3, align 4, !tbaa !5, !alias.scope !12, !noalias !9
  store <4 x float> %6, ptr %4, align 4, !tbaa !5, !alias.scope !12, !noalias !9
  %index.next = add nuw i64 %index, 8
  %7 = icmp eq i64 %index.next, %n.vec
  br i1 %7, label %middle.block, label %vector.body, !llvm.loop !14

middle.block:                                     ; preds = %vector.body
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader19

for.body.preheader19:                             ; preds = %vector.memcheck, %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %vector.memcheck ], [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  br label %for.body

for.cond.cleanup:                                 ; preds = %for.body, %middle.block, %entry
  ret void

for.body:                                         ; preds = %for.body.preheader19, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ %indvars.iv.ph, %for.body.preheader19 ]
  %arrayidx = getelementptr inbounds float, ptr %x, i64 %indvars.iv
  %8 = load float, ptr %arrayidx, align 4, !tbaa !5
  %arrayidx2 = getelementptr inbounds float, ptr %y, i64 %indvars.iv
  %9 = load float, ptr %arrayidx2, align 4, !tbaa !5
  %10 = tail call float @llvm.fmuladd.f32(float %a, float %8, float %9)
  store float %10, ptr %arrayidx2, align 4, !tbaa !5
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !llvm.loop !17
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare float @llvm.fmuladd.f32(float, float, float) #1

; Function Attrs: argmemonly nofree nosync nounwind ssp uwtable
define void @saxpy_restrict(float noundef %a, ptr noalias nocapture noundef readonly %x, ptr noalias nocapture noundef %y, i32 noundef %n) local_unnamed_addr #0 {
entry:
  %cmp10 = icmp sgt i32 %n, 0
  br i1 %cmp10, label %for.body.preheader, label %for.cond.cleanup

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %n to i64
  %min.iters.check = icmp ult i32 %n, 8
  br i1 %min.iters.check, label %for.body.preheader18, label %vector.ph

vector.ph:                                        ; preds = %for.body.preheader
  %n.vec = and i64 %wide.trip.count, 4294967288
  %broadcast.splatinsert = insertelement <4 x float> poison, float %a, i64 0
  %broadcast.splat = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <4 x i32> zeroinitializer
  %broadcast.splatinsert16 = insertelement <4 x float> poison, float %a, i64 0
  %broadcast.splat17 = shufflevector <4 x float> %broadcast.splatinsert16, <4 x float> poison, <4 x i32> zeroinitializer
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %0 = getelementptr inbounds float, ptr %x, i64 %index
  %wide.load = load <4 x float>, ptr %0, align 4, !tbaa !5
  %1 = getelementptr inbounds float, ptr %0, i64 4
  %wide.load13 = load <4 x float>, ptr %1, align 4, !tbaa !5
  %2 = getelementptr inbounds float, ptr %y, i64 %index
  %wide.load14 = load <4 x float>, ptr %2, align 4, !tbaa !5
  %3 = getelementptr inbounds float, ptr %2, i64 4
  %wide.load15 = load <4 x float>, ptr %3, align 4, !tbaa !5
  %4 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load, <4 x float> %wide.load14)
  %5 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat17, <4 x float> %wide.load13, <4 x float> %wide.load15)
  store <4 x float> %4, ptr %2, align 4, !tbaa !5
  store <4 x float> %5, ptr %3, align 4, !tbaa !5
  %index.next = add nuw i64 %index, 8
  %6 = icmp eq i64 %index.next, %n.vec
  br i1 %6, label %middle.block, label %vector.body, !llvm.loop !18

middle.block:                                     ; preds = %vector.body
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader18

for.body.preheader18:                             ; preds = %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  br label %for.body

for.cond.cleanup:                                 ; preds = %for.body, %middle.block, %entry
  ret void

for.body:                                         ; preds = %for.body.preheader18, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ %indvars.iv.ph, %for.body.preheader18 ]
  %arrayidx = getelementptr inbounds float, ptr %x, i64 %indvars.iv
  %7 = load float, ptr %arrayidx, align 4, !tbaa !5
  %arrayidx2 = getelementptr inbounds float, ptr %y, i64 %indvars.iv
  %8 = load float, ptr %arrayidx2, align 4, !tbaa !5
  %9 = tail call float @llvm.fmuladd.f32(float %a, float %7, float %8)
  store float %9, ptr %arrayidx2, align 4, !tbaa !5
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !llvm.loop !19
}

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare <4 x float> @llvm.fmuladd.v4f32(<4 x float>, <4 x float>, <4 x float>) #2

attributes #0 = { argmemonly nofree nosync nounwind ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn }
attributes #2 = { nocallback nofree nosync nounwind readnone speculatable willreturn }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"PIC Level", i32 2}
!2 = !{i32 7, !"uwtable", i32 2}
!3 = !{i32 7, !"frame-pointer", i32 1}
!4 = !{!"Homebrew clang version 15.0.7"}
!5 = !{!6, !6, i64 0}
!6 = !{!"float", !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = !{!10}
!10 = distinct !{!10, !11}
!11 = distinct !{!11, !"LVerDomain"}
!12 = !{!13}
!13 = distinct !{!13, !11}
!14 = distinct !{!14, !15, !16}
!15 = !{!"llvm.loop.mustprogress"}
!16 = !{!"llvm.loop.isvectorized", i32 1}
!17 = distinct !{!17, !15, !16}
!18 = distinct !{!18, !15, !16}
!19 = distinct !{!19, !15, !20, !16}
!20 = !{!"llvm.loop.unroll.runtime.disable"}
