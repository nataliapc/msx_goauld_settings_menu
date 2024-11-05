.org #8000

	; Print menu
	ld   hl, menuScr
	ld   de, $1800
	ld   bc, menuScr_end - menuScr
	call BIOS_copyToVram

	ld   a, 32
	ld   (LINLEN), a
	

; Main loop
bucle:
	; Print var1
	ld hl,#1905
	ld a,(var1_mapper)
	call print_on_off

	; Print var2
	ld hl,#1906
	ld a,(var2_megram)
	call print_on_off

	; Print var3
	ld hl,#1907
	ld a,(var3_scanln)
	call print_on_off

	; Print var4
	ld hl,#1908
	call BIOS_setCursor
	ld a,(var4_mapslt)
	add a,#30
	call BIOS_printChar

	; Wait for a key
wait_for_a_key:
	ei
	halt
	call BIOS_keyStatus
	jr z, bucle	;wait_for_a_key
	call BIOS_readChar
	or a
	jr z, bucle	;wait_for_a_key

	sub #31					; Key '1' pressed
	jr nz,tecla2

	ld a,(var1_mapper)
	xor 1
	ld (var1_mapper),a
	jr bucle

tecla2:						; Key '2' pressed
	dec a
	jr nz,tecla3

	ld a,(var2_megram)
	xor 1
	ld (var2_megram),a
	jr bucle

tecla3:						; Key '3' pressed
	dec a
	jr nz,tecla4

	ld a,(var3_scanln)
	xor 1
	ld (var3_scanln),a
	jr bucle

tecla4:						; Key '4' pressed
	dec a
	jr nz,tecla5

	ld a,(var4_mapslt)
	inc a
	cp a,4
	jr nz,no4
	xor a
no4:
	ld (var4_mapslt),a
	jr bucle_largo

tecla5:						; Key '5' pressed
	dec a
	jr nz,tecla6

	call get_config
	jr save_and_exit

tecla6:						; Key '6' pressed
	dec a
	jr nz,bucle_largo

	call get_config
	or #80					; Bit 7: reset
save_and_exit:
	out (#41),a
	call BIOS_clearScreen
	ret

bucle_largo:
	jp bucle


get_config:
	ld a,(var1_mapper)		; Bit 0: mapper enable
	ld b,a
	ld a,(var2_megram)		; Bit 1: megaram enable
	add a,a
	or b
	ld b,a
	ld a,(var3_scanln)		; Bit 3: scanlines enable
	add a,a
	add a,a
	add a,a
	or b
	ld b,a
	ld a,(var4_mapslt)		; Bits5,4: mapper slot
	add a,a
	add a,a
	add a,a
	add a,a
	or b
	ret

; Prints characters from memory until a 0 is found.
; Input    : HL - The text address 
print_string:
	ld a,(hl)
	or a
	ret z
	inc hl
	call BIOS_printChar
	jr print_string

; Set the cursor to L,H position and prints 'Off'/'On ' if A is 0 or not.
; Input    : H  - Y coordinate of cursor
;            L  - X coordinate of cursor
;            A  - Value to print (0:Off 1:On)
print_on_off:
	ld   b, a
	call BIOS_setCursor
	ld   a, b
	ld hl,offStr
	or a
	jr z,print_on_off_end
	ld hl,onStr
print_on_off_end:
	call print_string
	ret


; ############## Constants

onStr:
	.db "On ",0
offStr:
	.db "Off",0

menuScr:
	.incbin "../assets/menu_screen/menu_scr.sc1" SKIP $1800+7 SIZE 32*10
menuScr_end:

; ############## Variables

var1_mapper: db 1
var2_megram: db 1
var3_scanln: db 1
var4_mapslt: db 0


; ############## MSX BIOS

; ####### LDIRVM
; Address  : #005C
; Function : Block transfer to VRAM from memory
; Input    : BC - Block length
;            DE - Start address of VRAM
;            HL - Start address of memory
; Registers: All
BIOS_copyToVram equ #005c
; ####### CHSNS
; Address  : #009C
; Function : Tests the status of the keyboard buffer
; Output   : Zero flag set if buffer is empty, otherwise not set
; Registers: AF
BIOS_keyStatus equ #009C
; ####### CHGET
; Address  : #009F
; Function : One character input (waiting)
; Output   : A  - ASCII code of the input character
; Registers: AF
BIOS_readChar equ #009f
; ####### CLS
; Address  : #00C3
; Function : Clears the screen
; Registers: AF, BC, DE
; Remark   : Zero flag must be set to be able to run this routine
;            XOR A will do fine most of the time
BIOS_clearScreen equ #00c3
; ####### CHPUT
; Address  : #00A2
; Function : Displays one character
; Input    : A  - ASCII code of character to display
BIOS_printChar equ #00a2
; ####### POSIT
; Address  : #00C6
; Function : Moves cursor to the specified position
; Input    : H  - Y coordinate of cursor
;            L  - X coordinate of cursor
; Registers: AF
BIOS_setCursor equ #00c6


; ############## MSX System variables

FORCLR equ		$f3e9	; (BYTE) Foreground colour
BAKCLR equ		$f3ea	; (BYTE) Background colour
LINLEN equ		$f3b0	; (BYTE) Current screen width per line


; ############## MSX VT-52 Character Codes

VT_BEEP    equ	$07		; A beep sound
VT_UP      equ	$1e		; 27,"A"	; Cursor up
VT_DOWN    equ	$1f		; 27,"B"	; Cursor down
VT_RIGHT   equ	$1c		; 27,"C"	; Cursor right
VT_LEFT    equ	$1d		; 27,"D"	; Cursor left
VT_CLRSCR  equ	$0c		; 27,"E"	; Clear screen:	Clears the screen and moves the cursor to home
VT_HOME    equ	$0b		; 27,"H"	; Cursor home:	Move cursor to the upper left corner.

