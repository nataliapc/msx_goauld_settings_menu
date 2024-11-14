.ZILOG
.BIOS
.BIOSVARS

.org #8000

	; Screen 0 / 80 columns
	ld   a, 80
	ld   (LINL40), a
	call INITXT
	; Blink mode on
	ld   bc, #4f0c
	call WRTVDP
	ld   bc, #100d
	call WRTVDP

	; Print menu title
	ld   hl,#1a02
	call POSIT				; BIOS setCursor
	ld   hl,menuTitleStr
	call print_string
	; Top header line
	ld   a, #ff
	ld   bc, 30
	ld   hl, #0800
	call FILVRM				; BIOS fill VRAM

	; Print menu options
	ld   de, struct_list
.printmenu_loop:
	ld   a, (de)
	or   a
	jr   z, .printmenu_loop_end
	ld   ixl, a
	inc  de
	ld   a, (de)
	ld   ixh, a
	inc  de
	call print_struct
	ld   a,#ff
	call print_selection
	jr   .printmenu_loop
.printmenu_loop_end:


; Main loop
bucle:
	; Print Enable Mapper
	ld hl,#2b05
	ld a,(var_mapper)
	call print_on_off

	; Print Enable Megaram
	ld hl,#2b07
	ld a,(var_megram)
	call print_on_off

	; Print Ghost SCC
	ld hl,#2b09
	ld a,(var_ghtscc)
	call print_on_off

	; Print Enable Scanlines
	ld hl,#2b0b
	ld a,(var_scanln)
	call print_on_off

	; Print Mapper Slot
	ld hl,#3c05
	call POSIT				; BIOS setCursor
	ld a,(var_mapslt)
	add a,#30
	call CHPUT				; BIOS printChar

	; Print MegaRam Slot
	ld hl,#3c07
	call POSIT				; BIOS setCursor
	ld a,(var_megslt)
	add a,#30
	call CHPUT				; BIOS printChar

	; Wait for a key
wait_for_a_key:
	ei
	halt
	call CHSNS				; BIOS keyStatus
	jr z, wait_for_a_key
	call CHGET				; BIOS readChar
	or a
	jr z, wait_for_a_key

	sub #31					; Key '1' pressed
	jr nz,tecla2

	ld a,(var_mapper)
	xor 1
	ld (var_mapper),a
	jr bucle

tecla2:						; Key '2' pressed
	dec a
	jr nz,tecla3

	ld a,(var_megram)
	xor 1
	ld (var_megram),a
	jr bucle

tecla3:						; Key '3' pressed
	dec a
	jr nz,tecla4

	ld a,(var_scanln)
	xor 1
	ld (var_scanln),a
	jr bucle

tecla4:						; Key '4' pressed
	dec a
	jr nz,tecla5

	ld a,(var_mapslt)
	inc a
	cp 4
	jr nz,no4
	xor a
no4:
	ld (var_mapslt),a
	jp bucle

tecla5:						; Key '5' pressed
	dec a
	jr nz,tecla6

	jp update_settings

tecla6:						; Key '6' pressed
	dec a
	jp nz,bucle

	call update_settings
	ld a, #80				; Bit 7: reset
	out (#42), a
	ret

update_settings:
	call config_var2byte
	di
	ld  a, #48				; Set I/O device to Goauld (#48)
	out (#40),a
	ld  a, b				; Set Goauld settings
	out (#41),a
	ei
	call INITXT				; BIOS clearScreen
	ld   bc, #000d			; Blink mode off
	call WRTVDP
	ret

config_var2byte:
	ld a,(var_mapper)		; Bit 0: mapper enable
	ld b,a
	ld a,(var_megram)		; Bit 1: megaram enable
	add a,a
	or b
	ld b,a
	ld a,(var_scanln)		; Bit 3: scanlines enable
	add a,a
	add a,a
	add a,a
	or b
	ld b,a
	ld a,(var_mapslt)		; Bits5,4: mapper slot
	add a,a
	add a,a
	add a,a
	add a,a
	or b
	ld b, a
	ret

; Prints characters from memory until a 0 is found.
; Input    : HL - The text address 
print_string:
	ld a,(hl)
	or a
	ret z
	inc hl
	call CHPUT				; BIOS printChar
	jr print_string

; Set the cursor to L,H position and prints 'Off'/'On ' if A is 0 or not.
; Input    : H  - Y coordinate of cursor
;            L  - X coordinate of cursor
;            A  - Value to print (0:Off 1:On)
print_on_off:
	ld   b, a
	call POSIT				; BIOS setCursor
	ld   a, b
	ld hl,offStr
	or a
	jr z,print_on_off_end
	ld hl,onStr
print_on_off_end:
	call print_string
	ret

; Print the text of a struct
; Input    : IX - Struct address
print_struct:
	ld   l, (ix+STRUCT_POSXY+1)
	ld   h, (ix+STRUCT_POSXY)
	call POSIT				; BIOS setCursor
	ld   l, (ix+STRUCT_TEXT)
	ld   h, (ix+STRUCT_TEXT+1)
	call print_string
	ret

; Print the selection highlight on/off
; Input    : IX - Struct address
;            A  - 0:off #ff:on
print_selection:
	ld   b, 0
	ld   c, (ix+STRUCT_SEL_LEN)
	ld   l, (ix+STRUCT_SEL_START)
	ld   h, (ix+STRUCT_SEL_START+1)
	ld   a, #ff
	call FILVRM
	ret

; ############## Constants

menuTitleStr:
	.db "MSX Goa'uld Settings Menu v1.0",0
enableMapperStr:
	.db "Enable Mapper",0
enableMegaRamStr:
	.db "Enable MegaRam",0
slot1GhostStr:
	.db "Slot 1 Ghost SCC",0
enableScanlinesStr:
	.db "Enable Scanlines",0
saveExitStr:
	.db "Save & Exit",0
saveResetStr:
	.db "Save & Reset",0
slotStr:
	.db "Slot",0

onStr:
	.db "On ",0
offStr:
	.db "Off",0


; ############## Variables

var_mapper: db 1
var_megram: db 1
var_ghtscc: db 1
var_scanln: db 1
var_mapslt: db 0
var_megslt: db 0


; ############## Structs

STRUCT_POSXY		equ		0
STRUCT_KEY_UP		equ		STRUCT_POSXY + 2
STRUCT_KEY_DOWN		equ		STRUCT_KEY_UP + 2
STRUCT_KEY_LEFT		equ		STRUCT_KEY_DOWN + 2
STRUCT_KEY_RIGHT	equ		STRUCT_KEY_LEFT + 2
STRUCT_SEL_START	equ		STRUCT_KEY_RIGHT + 2
STRUCT_SEL_LEN		equ		STRUCT_SEL_START + 2
STRUCT_TEXT			equ		STRUCT_SEL_LEN + 1

struct_EnableMapper:
	.db 21, 5
	.dw struct_SaveReset, struct_EnableMegaRam, struct_MapperSlot, struct_MapperSlot
	.dw #0800 + 4*10 + 2
	.db 4
	.dw enableMapperStr

struct_EnableMegaRam:
	.db 21, 7
	.dw struct_EnableMapper, struct_Slot1GhostSCC, struct_MegaRamSlot, struct_MegaRamSlot
	.dw #0800 + 6*10 + 2
	.db 4
	.dw enableMegaRamStr

struct_Slot1GhostSCC:
	.db 21, 9
	.dw struct_EnableMegaRam, struct_EnableScanlines, struct_Slot1GhostSCC, struct_Slot1GhostSCC
	.dw #0800 + 8*10 + 2
	.db 4
	.dw slot1GhostStr

struct_EnableScanlines:
	.db 21, 11
	.dw struct_Slot1GhostSCC, struct_EnableScanlines, struct_EnableScanlines, struct_EnableScanlines
	.dw #0800 + 10*10 + 2
	.db 4
	.dw enableScanlinesStr

struct_SaveExit:
	.db 21, 13
	.dw struct_EnableScanlines, struct_SaveReset, struct_SaveExit, struct_SaveExit
	.dw #0800 + 12*10 + 2
	.db 4
	.dw saveExitStr

struct_SaveReset:
	.db 21, 15
	.dw struct_SaveExit, struct_EnableMapper, struct_SaveReset, struct_SaveReset
	.dw #0800 + 14*10 + 2
	.db 4
	.dw saveResetStr

struct_MapperSlot:
	.db 55, 5
	.dw struct_MegaRamSlot, struct_MegaRamSlot, struct_EnableMapper, struct_EnableMapper
	.dw #0800 + 4*10 + 6
	.db 2
	.dw slotStr

struct_MegaRamSlot:
	.db 55, 7
	.dw struct_MapperSlot, struct_MapperSlot, struct_EnableMegaRam, struct_EnableMegaRam
	.dw #0800 + 6*10 + 6
	.db 2
	.dw slotStr

struct_list:
	.dw struct_EnableMapper, struct_MapperSlot, struct_EnableMegaRam, struct_MegaRamSlot
	.dw struct_Slot1GhostSCC, struct_EnableScanlines, struct_SaveExit, struct_SaveReset
	.db 0


; ############## MSX System variables

;FORCLR equ		#f3e9	; (BYTE) Foreground colour
;BAKCLR equ		#f3ea	; (BYTE) Background colour
;LINLEN equ		#f3b0	; (BYTE) Current screen width per line


; ############## MSX VT-52 Character Codes

VT_BEEP    equ	#07		; A beep sound
VT_UP      equ	#1e		; 27,"A"	; Cursor up
VT_DOWN    equ	#1f		; 27,"B"	; Cursor down
VT_RIGHT   equ	#1c		; 27,"C"	; Cursor right
VT_LEFT    equ	#1d		; 27,"D"	; Cursor left
VT_CLRSCR  equ	#0c		; 27,"E"	; Clear screen:	Clears the screen and moves the cursor to home
VT_HOME    equ	#0b		; 27,"H"	; Cursor home:	Move cursor to the upper left corner.

