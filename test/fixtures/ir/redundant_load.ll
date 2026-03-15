; Redundant load: two loads from same pointer in same block; loop-invariant load.
define i32 @redundant_in_block(i32* %p) {
entry:
  %a = load i32, i32* %p
  %b = load i32, i32* %p
  %s = add i32 %a, %b
  ret i32 %s
}

define i32 @invariant_in_loop(i32* %p, i32 %n) {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %sum, %loop ]
  %v = load i32, i32* %p
  %sum = add i32 %acc, %v
  %i.next = add i32 %i, 1
  %cmp = icmp slt i32 %i.next, %n
  br i1 %cmp, label %loop, label %exit

exit:
  ret i32 %sum
}
