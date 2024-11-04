org #7d40

;	call CHSNS
;	ret z
;	call read_char
;	cp a,#67
;	ret nz

	; Initialize RAM variables
	ld hl, var_init_start
	ld de, var_ram
	ld bc, var_init_end-var_init_start
	ldir

	; Print menu
	ld hl,#0101
	call set_cursor
	ld hl,menuStr
	call print_string

; Main loop
bucle:
	; Print var1
	ld hl,#1402
	ld a,(var1_mapper)
	call print_on_off

	; Print var2
	ld hl,#1403
	ld a,(var2_megram)
	call print_on_off

	; Print var3
	ld hl,#1404
	ld a,(var3_scanln)
	call print_on_off

	; Print var4
	ld hl,#1405
	call set_cursor
	ld a,(var4_mapslt)
	add a,#30
	call print_char

	; Wait for a key
wait_for_a_key:
	call CHSNS
	jr z, wait_for_a_key
	call read_char
	or a
	jr z, wait_for_a_key

	; Key '1' pressed
	sub #31
	jr nz,tecla2

	ld a,(var1_mapper)
	xor 1
	ld (var1_mapper),a
	jr bucle

tecla2:
	; Key '2' pressed
	dec a
	jr nz,tecla3

	ld a,(var2_megram)
	xor 1
	ld (var2_megram),a
	jr bucle

tecla3:
	; Key '3' pressed
	dec a
	jr nz,tecla4

	ld a,(var3_scanln)
	xor 1
	ld (var3_scanln),a
	jr bucle_largo

tecla4:
	; Key '4' pressed
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

tecla5:
	; Key '5' pressed
	dec a
	jr nz,tecla6
	call get_config
	out (#41),a
	ret

tecla6:
	; Key '6' pressed
	dec a
	jr nz,bucle_largo
	call get_config
	or #80
	out (#41),a
	ret

bucle_largo:
	jp bucle

get_config:
	ld a,(var1_mapper)
	ld b,a
	ld a,(var2_megram)
	sla a
	or b
	ld b,a
	ld a,(var3_scanln)
	sla a
	sla a
	sla a
	or b
	ld b,a
	ld a,(var4_mapslt)
	sla a
	sla a
	sla a
	sla a
	or b
	ret

; Prints characters from memory until a 0 is found.
; Input    : HL - The text address 
print_string:
	ld a,(hl)
	or a
	ret z
	inc hl
	call print_char
	jr print_string

; Set the cursor to L,H position and prints 'Off'/'On ' if A is 0 or not.
; Input    : H  - Y coordinate of cursor
;            L  - X coordinate of cursor
;            A  - Value to print (0:Off 1:On)
print_on_off:
	ld   b, a
	call set_cursor
	ld   a, b
	ld hl,offStr
	or a
	jr z,print_on_off_end
	ld hl,onStr
print_on_off_end:
	call print_string
	ret

; ############## Variables

var_init_start:
	var1_init: db 1
	var2_init: db 1
	var3_init: db 1
	var4_init: db 0
var_init_end:

var_ram equ #8000
var1_mapper equ var_ram+0
var2_megram equ var_ram+1
var3_scanln equ var_ram+2
var4_mapslt equ var_ram+3

; ############## Constants

menuStr:
	db "Goauld Config",#0d,#0a
	db "1-Enable Mapper",#0d,#0a
	db "2-Enable Megaram",#0d,#0a
	db "3-Enable Scanlines",#0d,#0a
	db "4-Mapper Slot",#0d,#0a
	db "5-Save & Exit",#0d,#0a
	db "6-Save & Reset",0
onStr: db "On ",0
offStr: db "Off",0

; ############## MSX BIOS

; ####### CHPUT
; Address  : #00A2
; Function : Displays one character
; Input    : A  - ASCII code of character to display
print_char equ #00a2
; ####### POSIT
; Address  : #00C6
; Function : Moves cursor to the specified position
; Input    : H  - Y coordinate of cursor
;            L  - X coordinate of cursor
; Registers: AF
set_cursor equ #00c6
; ####### CHGET
; Address  : #009F
; Function : One character input (waiting)
; Output   : A  - ASCII code of the input character
; Registers: AF
read_char equ #009f
; ####### CHSNS
; Address  : #009C
; Function : Tests the status of the keyboard buffer
; Output   : Zero flag set if buffer is empty, otherwise not set
; Registers: AF
CHSNS equ #009C
