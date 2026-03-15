; ModuleID = 'matmul.cpp'
source_filename = "matmul.cpp"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx16.0.0"

; Function Attrs: argmemonly mustprogress nofree nosync nounwind ssp uwtable
define void @_Z13matmul_kernelPKfS0_Pfi(ptr nocapture noundef readonly %0, ptr nocapture noundef readonly %1, ptr nocapture noundef writeonly %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = icmp sgt i32 %3, 0
  br i1 %5, label %6, label %17

6:                                                ; preds = %4
  %7 = sext i32 %3 to i64
  %8 = sext i32 %3 to i64
  %9 = sext i32 %3 to i64
  %10 = zext i32 %3 to i64
  %11 = zext i32 %3 to i64
  %12 = zext i32 %3 to i64
  br label %13

13:                                               ; preds = %6, %20
  %14 = phi i64 [ 0, %6 ], [ %21, %20 ]
  %15 = mul nsw i64 %14, %8
  %16 = mul nsw i64 %14, %9
  br label %18

17:                                               ; preds = %20, %4
  ret void

18:                                               ; preds = %13, %23
  %19 = phi i64 [ 0, %13 ], [ %26, %23 ]
  br label %28

20:                                               ; preds = %23
  %21 = add nuw nsw i64 %14, 1
  %22 = icmp eq i64 %21, %10
  br i1 %22, label %17, label %13, !llvm.loop !5

23:                                               ; preds = %28
  %24 = add nsw i64 %19, %16
  %25 = getelementptr inbounds float, ptr %2, i64 %24
  store float %38, ptr %25, align 4, !tbaa !8
  %26 = add nuw nsw i64 %19, 1
  %27 = icmp eq i64 %26, %11
  br i1 %27, label %20, label %18, !llvm.loop !12

28:                                               ; preds = %18, %28
  %29 = phi i64 [ 0, %18 ], [ %39, %28 ]
  %30 = phi float [ 0.000000e+00, %18 ], [ %38, %28 ]
  %31 = add nsw i64 %29, %15
  %32 = getelementptr inbounds float, ptr %0, i64 %31
  %33 = load float, ptr %32, align 4, !tbaa !8
  %34 = mul nsw i64 %29, %7
  %35 = add nsw i64 %34, %19
  %36 = getelementptr inbounds float, ptr %1, i64 %35
  %37 = load float, ptr %36, align 4, !tbaa !8
  %38 = tail call float @llvm.fmuladd.f32(float %33, float %37, float %30)
  %39 = add nuw nsw i64 %29, 1
  %40 = icmp eq i64 %39, %12
  br i1 %40, label %23, label %28, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn
declare float @llvm.fmuladd.f32(float, float, float) #1

attributes #0 = { argmemonly mustprogress nofree nosync nounwind ssp uwtable "frame-pointer"="non-leaf" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind readnone speculatable willreturn }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"PIC Level", i32 2}
!2 = !{i32 7, !"uwtable", i32 2}
!3 = !{i32 7, !"frame-pointer", i32 1}
!4 = !{!"Homebrew clang version 15.0.7"}
!5 = distinct !{!5, !6, !7}
!6 = !{!"llvm.loop.mustprogress"}
!7 = !{!"llvm.loop.unroll.disable"}
!8 = !{!9, !9, i64 0}
!9 = !{!"float", !10, i64 0}
!10 = !{!"omnipotent char", !11, i64 0}
!11 = !{!"Simple C++ TBAA"}
!12 = distinct !{!12, !6, !7}
!13 = distinct !{!13, !6, !7}
