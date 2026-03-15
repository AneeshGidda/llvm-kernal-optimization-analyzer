; Loop with multiple conditional branches in body - should trigger "likely blocked" vectorization.
define void @branch_heavy(i32* %p, i32 %n, i32 %a, i32 %b) {
entry:
  br label %for.body

for.body:
  %i = phi i32 [ 0, %entry ], [ %i.next, %latch ]
  %ptr = getelementptr i32, i32* %p, i32 %i
  %v = load i32, i32* %ptr
  %c1 = icmp sgt i32 %v, %a
  br i1 %c1, label %then1, label %else1

then1:
  %x = add i32 %v, 1
  br label %mid

else1:
  %y = sub i32 %v, 1
  br label %mid

mid:
  %z = phi i32 [ %x, %then1 ], [ %y, %else1 ]
  %c2 = icmp slt i32 %z, %b
  br i1 %c2, label %then2, label %latch

then2:
  store i32 %z, i32* %ptr
  br label %latch

latch:
  %i.next = add i32 %i, 1
  %cmp = icmp slt i32 %i.next, %n
  br i1 %cmp, label %for.body, label %exit

exit:
  ret void
}
