	.file	"asmb.c"
	.text
	.globl	asmb
	.type	asmb, @function
asmb:
.LFB0:
	.cfi_startproc

	movq %rdi, %rax # copy array pointer to return register
start:
	cmpq %rsi, const_0(%rip) # compare if rsi is 0; use rip relative addressing
	je end # jump equal (when zero flag) to end

	movq $64, %rcx	# load 64 into %rcx
	movq $64, %r8	# load 64 into %r8

	# only calculate shift range when %rsi < 64
	cmpq %rsi, const_64(%rip)	# 64 - %rsi 
	cmovaq %rsi, %r8 # conditional move if carry of result is zero (rsi is below 64)
	subq %r8, %rcx	# substract %r8 from %rcx, 1 <= %r8 <= 64

	movq $-1, %rdx	# set rdx to 1s only
	shrq %rcx, %rdx	# shift rdx by rcx ro the right

	# load computed mask into a masking-register
	kmovq %rdx, %k1

	# load SIMD register
	vmovdqu8 (%rdi), %zmm8{%k1}
	
	# preparation for compare
	movq $97, %rcx # write into temp register
	movq %rcx, %xmm9 # write value (97) into the SIMD-Register (lower 64 bit)
	vpbroadcastb %xmm9, %zmm10 # write lower byte into all 64 positions (into 512-bit-register)

	# compare >= 'a' 97
	# "nlt" stands for "not less than"
	# compare only the "k1-masked" values (only check valid array values); result into flag-register k2
	vpcmpnltub %zmm10, %zmm8, %k2{%k1} 
	
	# preparation for compare
	movq $122, %rcx
	movq %rcx, %xmm9
	vpbroadcastb %xmm9, %zmm10 # write lower byte into all 64 positions (into 512-bit-register)

	# compare <= 'z' (122)
	# "le" stands for "less (or) equal"
	# only check where the previous comparison is already "true" --> basically a && - operation
	vpcmpleub %zmm10, %zmm8, %k1{%k2}

	movq $-32, %rcx # -32 is the difference betweens lower case and upper case characters in ASCII
	movq %rcx, %xmm9
	vpbroadcastb %xmm9, %zmm10 # write lower byte into all 64 positions (into 512-bit-register)

	# add -32 (subtract 32) to get character as upper character
	vpaddb %zmm10, %zmm8, %zmm8{%k1}

	# store result in memory / return result
	vmovdqu8 %zmm8, (%rdi){%k1}

	# next loop
	subq $64, %rsi
	cmovbq const_0(%rip), %rsi # rsi is capped at 0 to prevent overflow

	addq $64, %rdi # increase pointer by 64 byte
	jmp start
	
end:
	ret
	.cfi_endproc
.LFE0:
	.size	asmb, .-asmb
	.ident	"GCC: (Debian 10.2.1-6) 10.2.1 20210110"
	.section	.note.GNU-stack,"",@progbits

	.data

const_64:	.fill 1, 8, 64
const_0:	.fill 1, 8, 0
