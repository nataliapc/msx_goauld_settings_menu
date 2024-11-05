.org #7d40

	call BIOS_keyStatus
	ret  z
	call BIOS_readChar
	cp   a, #67
	ret  nz

	ld      hl, compressed_code
	ld      de, menu_main
	push    de

decompressor:
	.include "../src/dzx7mini.asm"


; -----------------------------------------------------------------------------
; Compressed main menu code:
; -----------------------------------------------------------------------------
compressed_code:
	.incbin "menu_main.zx7"

menu_main equ #8000

BIOS_keyStatus equ #009C
BIOS_readChar equ #009f