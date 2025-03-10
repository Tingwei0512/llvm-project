; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -enable-vplan-native-path -passes=loop-vectorize -S %s | FileCheck %s

; Make sure phi nodes are generated correctly, even if the use list order of
; the predecessors in the scalar code does not match the order in the generated
; vector blocks.

; Test from PR45958.

define void @test(ptr %src, i64 %n) {
; CHECK-LABEL: @test(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[MIN_ITERS_CHECK:%.*]] = icmp ult i64 [[N:%.*]], 4
; CHECK-NEXT:    br i1 [[MIN_ITERS_CHECK]], label [[SCALAR_PH:%.*]], label [[VECTOR_PH:%.*]]
; CHECK:       vector.ph:
; CHECK-NEXT:    [[N_MOD_VF:%.*]] = urem i64 [[N]], 4
; CHECK-NEXT:    [[N_VEC:%.*]] = sub i64 [[N]], [[N_MOD_VF]]
; CHECK-NEXT:    [[BROADCAST_SPLATINSERT:%.*]] = insertelement <4 x i64> poison, i64 [[N]], i64 0
; CHECK-NEXT:    [[BROADCAST_SPLAT:%.*]] = shufflevector <4 x i64> [[BROADCAST_SPLATINSERT]], <4 x i64> poison, <4 x i32> zeroinitializer
; CHECK-NEXT:    br label [[VECTOR_BODY:%.*]]
; CHECK:       vector.body:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i64 [ 0, [[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], [[LOOP_1_LATCH5:%.*]] ]
; CHECK-NEXT:    [[VEC_IND:%.*]] = phi <4 x i64> [ <i64 0, i64 1, i64 2, i64 3>, [[VECTOR_PH]] ], [ [[VEC_IND_NEXT:%.*]], [[LOOP_1_LATCH5]] ]
; CHECK-NEXT:    br label [[LOOP_2_HEADER1:%.*]]
; CHECK:       loop.2.header1:
; CHECK-NEXT:    [[VEC_PHI:%.*]] = phi <4 x i64> [ zeroinitializer, [[VECTOR_BODY]] ], [ [[TMP5:%.*]], [[LOOP_2_LATCH4:%.*]] ]
; CHECK-NEXT:    br label [[LOOP_32:%.*]]
; CHECK:       loop.32:
; CHECK-NEXT:    [[VEC_PHI3:%.*]] = phi <4 x i64> [ zeroinitializer, [[LOOP_2_HEADER1]] ], [ [[TMP2:%.*]], [[LOOP_32]] ]
; CHECK-NEXT:    [[TMP0:%.*]] = getelementptr inbounds [2000 x i32], ptr [[SRC:%.*]], <4 x i64> [[VEC_IND]], <4 x i64> [[VEC_PHI3]]
; CHECK-NEXT:    [[WIDE_MASKED_GATHER:%.*]] = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> [[TMP0]], i32 4, <4 x i1> splat (i1 true), <4 x i32> poison)
; CHECK-NEXT:    [[TMP1:%.*]] = mul nsw <4 x i32> [[WIDE_MASKED_GATHER]], splat (i32 10)
; CHECK-NEXT:    call void @llvm.masked.scatter.v4i32.v4p0(<4 x i32> [[TMP1]], <4 x ptr> [[TMP0]], i32 4, <4 x i1> splat (i1 true))
; CHECK-NEXT:    [[TMP2]] = add nuw nsw <4 x i64> [[VEC_PHI3]], splat (i64 1)
; CHECK-NEXT:    [[TMP3:%.*]] = icmp eq <4 x i64> [[TMP2]], [[BROADCAST_SPLAT]]
; CHECK-NEXT:    [[TMP4:%.*]] = extractelement <4 x i1> [[TMP3]], i32 0
; CHECK-NEXT:    br i1 [[TMP4]], label [[LOOP_2_LATCH4]], label [[LOOP_32]]
; CHECK:       loop.2.latch4:
; CHECK-NEXT:    [[TMP5]] = add nuw nsw <4 x i64> [[VEC_PHI]], splat (i64 1)
; CHECK-NEXT:    [[TMP6:%.*]] = icmp eq <4 x i64> [[TMP5]], [[BROADCAST_SPLAT]]
; CHECK-NEXT:    [[TMP7:%.*]] = extractelement <4 x i1> [[TMP6]], i32 0
; CHECK-NEXT:    br i1 [[TMP7]], label [[LOOP_1_LATCH5]], label [[LOOP_2_HEADER1]]
; CHECK:       vector.latch:
; CHECK-NEXT:    [[INDEX_NEXT]] = add nuw i64 [[INDEX]], 4
; CHECK-NEXT:    [[VEC_IND_NEXT]] = add <4 x i64> [[VEC_IND]], splat (i64 4)
; CHECK-NEXT:    [[TMP10:%.*]] = icmp eq i64 [[INDEX_NEXT]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[TMP10]], label [[MIDDLE_BLOCK:%.*]], label [[VECTOR_BODY]], !llvm.loop [[LOOP0:![0-9]+]]
; CHECK:       middle.block:
; CHECK-NEXT:    [[CMP_N:%.*]] = icmp eq i64 [[N]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[CMP_N]], label [[EXIT:%.*]], label [[SCALAR_PH]]
; CHECK:       scalar.ph:
; CHECK-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i64 [ [[N_VEC]], [[MIDDLE_BLOCK]] ], [ 0, [[ENTRY:%.*]] ]
; CHECK-NEXT:    br label [[LOOP_1_HEADER:%.*]]
; CHECK:       loop.1.header:
; CHECK-NEXT:    [[IV_1:%.*]] = phi i64 [ [[BC_RESUME_VAL]], [[SCALAR_PH]] ], [ [[IV_1_NEXT:%.*]], [[LOOP_1_LATCH:%.*]] ]
; CHECK-NEXT:    br label [[LOOP_2_HEADER:%.*]]
; CHECK:       loop.2.header:
; CHECK-NEXT:    [[IV_2:%.*]] = phi i64 [ 0, [[LOOP_1_HEADER]] ], [ [[IV_2_NEXT:%.*]], [[LOOP_2_LATCH:%.*]] ]
; CHECK-NEXT:    br label [[LOOP_3:%.*]]
; CHECK:       loop.3:
; CHECK-NEXT:    [[IV_3:%.*]] = phi i64 [ 0, [[LOOP_2_HEADER]] ], [ [[IV_3_NEXT:%.*]], [[LOOP_3]] ]
; CHECK-NEXT:    [[GEP_SRC:%.*]] = getelementptr inbounds [2000 x i32], ptr [[SRC]], i64 [[IV_1]], i64 [[IV_3]]
; CHECK-NEXT:    [[L1:%.*]] = load i32, ptr [[GEP_SRC]], align 4
; CHECK-NEXT:    [[MUL:%.*]] = mul nsw i32 [[L1]], 10
; CHECK-NEXT:    store i32 [[MUL]], ptr [[GEP_SRC]], align 4
; CHECK-NEXT:    [[IV_3_NEXT]] = add nuw nsw i64 [[IV_3]], 1
; CHECK-NEXT:    [[EC_3:%.*]] = icmp eq i64 [[IV_3_NEXT]], [[N]]
; CHECK-NEXT:    br i1 [[EC_3]], label [[LOOP_2_LATCH]], label [[LOOP_3]]
; CHECK:       loop.2.latch:
; CHECK-NEXT:    [[IV_2_NEXT]] = add nuw nsw i64 [[IV_2]], 1
; CHECK-NEXT:    [[EC_2:%.*]] = icmp eq i64 [[IV_2_NEXT]], [[N]]
; CHECK-NEXT:    br i1 [[EC_2]], label [[LOOP_1_LATCH]], label [[LOOP_2_HEADER]]
; CHECK:       loop.1.latch:
; CHECK-NEXT:    [[IV_1_NEXT]] = add nuw nsw i64 [[IV_1]], 1
; CHECK-NEXT:    [[EC_1:%.*]] = icmp eq i64 [[IV_1_NEXT]], [[N]]
; CHECK-NEXT:    br i1 [[EC_1]], label [[EXIT]], label [[LOOP_1_HEADER]], !llvm.loop [[LOOP3:![0-9]+]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  br label %loop.1.header

loop.1.header:
  %iv.1 = phi i64 [ 0, %entry ], [ %iv.1.next, %loop.1.latch ]
  br label %loop.2.header

loop.2.header:
  %iv.2 = phi i64 [ 0, %loop.1.header ], [ %iv.2.next, %loop.2.latch ]
  br label %loop.3

loop.3:
  %iv.3 = phi i64 [ 0, %loop.2.header ], [ %iv.3.next, %loop.3 ]
  %gep.src = getelementptr inbounds [2000 x i32], ptr %src, i64 %iv.1, i64 %iv.3
  %l1 = load i32, ptr %gep.src, align 4
  %mul = mul nsw i32 %l1, 10
  store i32 %mul, ptr %gep.src, align 4
  %iv.3.next = add nuw nsw i64 %iv.3, 1
  %ec.3 = icmp eq i64 %iv.3.next, %n
  br i1 %ec.3, label %loop.2.latch, label %loop.3

loop.2.latch:
  %iv.2.next = add nuw nsw i64 %iv.2, 1
  %ec.2 = icmp eq i64 %iv.2.next, %n
  br i1 %ec.2, label %loop.1.latch, label %loop.2.header

loop.1.latch:
  %iv.1.next = add nuw nsw i64 %iv.1, 1
  %ec.1 = icmp eq i64 %iv.1.next, %n
  br i1 %ec.1, label %exit, label %loop.1.header, !llvm.loop !0

exit:                                             ; preds = %loop.1.latch
  ret void

; uselistorder directives
  uselistorder label %loop.3, { 1, 0 }
  uselistorder label %loop.2.header, { 1, 0 }
}

!0 = distinct !{!0, !1, !2}
!1 = !{!"llvm.loop.vectorize.width", i32 4}
!2 = !{!"llvm.loop.vectorize.enable", i1 true}
