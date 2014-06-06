	.section	__TEXT,__text,regular,pure_instructions
	.macosx_version_min 12, 5
	.globl	_foo
	.align	4, 0x90
_foo:
	movl	%edi, -4(%rsp)
	movl	%esi, -8(%rsp)
	movl	-4(%rsp), %esi
	addl	-8(%rsp), %esi
	movl	%esi, %eax
	retq

	.globl	_foz
	.align	4, 0x90
_foz:
	movl	%edi, -4(%rsp)
	movl	%esi, -8(%rsp)
	movl	-4(%rsp), %esi
	imull	-8(%rsp), %esi
	cvtsi2ssl	%esi, %xmm0
	retq

	.globl	_bar
	.align	4, 0x90
_bar:
	subq	$24, %rsp
	movl	%edi, 12(%rsp)
	movl	12(%rsp), %edi
	movl	12(%rsp), %eax
	subl	$2, %eax
	movl	%edi, 20(%rsp)
	movl	%eax, 16(%rsp)
	movl	20(%rsp), %eax
	addl	16(%rsp), %eax
	cvtsi2ssl	%eax, %xmm0
	movl	12(%rsp), %eax
	subl	$2, %eax
	movl	12(%rsp), %esi
	movl	%eax, %edi
	movss	%xmm0, 8(%rsp)
	callq	_foz
	movss	8(%rsp), %xmm1
	mulss	%xmm0, %xmm1
	cvttss2si	%xmm1, %eax
	addq	$24, %rsp
	retq


.subsections_via_symbols
