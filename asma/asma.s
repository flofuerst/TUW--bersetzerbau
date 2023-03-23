	.file	"asma.c"
	.text
	.globl	asma
	.type	asma, @function
asma:
.LFB0:
	.cfi_startproc
	
	# bitmask:
	# 0xffff...>>(64-n)
	movq $64, %rcx	# load 64 into rcx
	subq %rsi, %rcx	# subtract second parameter (n) from rcx (rcx = rcx (64) - rsi)
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
	movq %rdi, %rax

	ret
	.cfi_endproc
.LFE0:
	.size	asma, .-asma
	.ident	"GCC: (GNU) 12.2.1 20230201"
	.section	.note.GNU-stack,"",@progbits
