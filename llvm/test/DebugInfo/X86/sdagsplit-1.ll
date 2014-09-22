; RUN: %llc_dwarf -filetype=obj < %s | llvm-dwarfdump - | FileCheck %s
;
; Test that we can emit debug info for large values that are split
; up across multiple registers by the SelectionDAG type legalizer.
;
;    // Compile with -O1 -m32.
;    long long foo (long long a, long long b)
;    {
;      long long res = b+1;
;      if ( a == b )
;        return res;
;      return 0;
;    }
;
; CHECK: DW_AT_location [DW_FORM_data4]        ([[LOC:.*]])
; CHECK-NEXT:  DW_AT_name {{.*}}"res"
; CHECK: .debug_loc
; CHECK: [[LOC]]:
; eax, piece 0x00000004, edx, piece 0x00000004
; CHECK:   Location description: 50 93 04 52 93 04

; ModuleID = 'sdagsplit-1.c'
target datalayout = "e-m:o-p:32:32-f64:32:64-f80:128-n8:16:32-S128"
target triple = "i386-apple-macosx10.9.0"

; Function Attrs: nounwind readnone ssp
define i64 @foo(i64 %a, i64 %b) #0 {
entry:
  tail call void @llvm.dbg.value(metadata !{i64 %a}, i64 0, metadata !10), !dbg !17
  tail call void @llvm.dbg.value(metadata !{i64 %b}, i64 0, metadata !11), !dbg !18
  %cmp = icmp eq i64 %a, %b, !dbg !21
  %add = add nsw i64 %b, 1, !dbg !23
  tail call void @llvm.dbg.value(metadata !{i64 %add}, i64 0, metadata !13), !dbg !20
  %retval.0 = select i1 %cmp, i64 %add, i64 0, !dbg !21
  ret i64 %retval.0, !dbg !24
}

; Function Attrs: nounwind readnone
declare void @llvm.dbg.value(metadata, i64, metadata) #1

attributes #0 = { nounwind readnone ssp }
attributes #1 = { nounwind readnone }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!14, !15}
!llvm.ident = !{!16}

!0 = metadata !{i32 786449, metadata !1, i32 12, metadata !"clang version 3.6.0 ", i1 true, metadata !"", i32 0, metadata !2, metadata !2, metadata !3, metadata !2, metadata !2, metadata !"", i32 1} ; [ DW_TAG_compile_unit ] [/sdagsplit-1.c] [DW_LANG_C99]
!1 = metadata !{metadata !"sdagsplit-1.c", metadata !""}
!2 = metadata !{}
!3 = metadata !{metadata !4}
!4 = metadata !{i32 786478, metadata !1, metadata !5, metadata !"foo", metadata !"foo", metadata !"", i32 2, metadata !6, i1 false, i1 true, i32 0, i32 0, null, i32 256, i1 true, i64 (i64, i64)* @foo, null, null, metadata !9, i32 3} ; [ DW_TAG_subprogram ] [line 2] [def] [scope 3] [foo]
!5 = metadata !{i32 786473, metadata !1}          ; [ DW_TAG_file_type ] [/sdagsplit-1.c]
!6 = metadata !{i32 786453, i32 0, null, metadata !"", i32 0, i64 0, i64 0, i64 0, i32 0, null, metadata !7, i32 0, null, null, null} ; [ DW_TAG_subroutine_type ] [line 0, size 0, align 0, offset 0] [from ]
!7 = metadata !{metadata !8, metadata !8, metadata !8, metadata !8}
!8 = metadata !{i32 786468, null, null, metadata !"long long int", i32 0, i64 64, i64 32, i64 0, i32 0, i32 5} ; [ DW_TAG_base_type ] [long long int] [line 0, size 64, align 32, offset 0, enc DW_ATE_signed]
!9 = metadata !{metadata !10, metadata !11, metadata !13}
!10 = metadata !{i32 786689, metadata !4, metadata !"a", metadata !5, i32 16777218, metadata !8, i32 0, i32 0} ; [ DW_TAG_arg_variable ] [a] [line 2]
!11 = metadata !{i32 786689, metadata !4, metadata !"b", metadata !5, i32 33554434, metadata !8, i32 0, i32 0} ; [ DW_TAG_arg_variable ] [b] [line 2]
!13 = metadata !{i32 786688, metadata !4, metadata !"res", metadata !5, i32 4, metadata !8, i32 0, i32 0} ; [ DW_TAG_auto_variable ] [res] [line 4]
!14 = metadata !{i32 2, metadata !"Dwarf Version", i32 2}
!15 = metadata !{i32 2, metadata !"Debug Info Version", i32 1}
!16 = metadata !{metadata !"clang version 3.6.0 "}
!17 = metadata !{i32 2, i32 26, metadata !4, null}
!18 = metadata !{i32 2, i32 39, metadata !4, null}
!19 = metadata !{i32 2, i32 52, metadata !4, null}
!20 = metadata !{i32 4, i32 13, metadata !4, null}
!21 = metadata !{i32 5, i32 8, metadata !22, null}
!22 = metadata !{i32 786443, metadata !1, metadata !4, i32 5, i32 8, i32 0, i32 0} ; [ DW_TAG_lexical_block ] [/sdagsplit-1.c]
!23 = metadata !{i32 4, i32 3, metadata !4, null}
!24 = metadata !{i32 8, i32 1, metadata !4, null} ; [ DW_TAG_imported_declaration ]
