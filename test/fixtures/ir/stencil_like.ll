; Stencil-like: multiple loads per iteration from same/neighboring addresses (memory density).
define void @stencil(i32* %in, i32* %out, i32 %n) {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %c = getelementptr i32, i32* %in, i32 %i
  %l0 = load i32, i32* %c
  %p1 = getelementptr i32, i32* %in, i32 %i
  %off = add i32 %i, 1
  %p2 = getelementptr i32, i32* %in, i32 %off
  %l1 = load i32, i32* %p2
  %off2 = add i32 %i, 2
  %p3 = getelementptr i32, i32* %in, i32 %off2
  %l2 = load i32, i32* %p3
  %s = add i32 %l0, %l1
  %t = add i32 %s, %l2
  %out.ptr = getelementptr i32, i32* %out, i32 %i
  store i32 %t, i32* %out.ptr
  %i.next = add i32 %i, 1
  %cmp = icmp slt i32 %i.next, %n
  br i1 %cmp, label %loop, label %exit

exit:
  ret void
}
