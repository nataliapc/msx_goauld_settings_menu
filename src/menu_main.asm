.ZILOG
.BIOS
.BIOSVARS

.org #8000

; ############## Initialization

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
	call POSIT						; BIOS setCursor
	ld   hl,menuTitleStr
	call print_string
	; Top header line
	ld   a, #ff
	ld   bc, 30
	ld   hl, #0800
	call FILVRM						; BIOS fill VRAM

	; Print menu options
	ld   ix, structs_start
	ld   (var_currentStruct), ix
.printmenu_loop:
	ld   a, (ix)
	or   a
	jr   z, .printmenu_loop_end
	call print_struct
	ld   bc, STRUCT_SIZE
	add  ix, bc
	jr   .printmenu_loop
.printmenu_loop_end:

	; Read Goauld settings
	di
	ld  a, #48						; Set I/O device to Goauld (#48)
	out (#40),a
	in  a,(#41)
	ei
	; Set initial variables values
	ld b,a
	and #01							; Bit 0: mapper enable
	ld (var_mapper),a
	ld a,b
	and #02							; Bit 1: megaram enable
	srl a
	ld (var_megram),a
	ld a,b
	and #04							; Bit 2: ghost scc enable
	srl a
	srl a
	ld (var_ghtscc),a
	ld a,b
	and #08							; Bit 3: scanlines enable
	srl a
	srl a
	srl a
	ld (var_scanln),a
	ld a,b
	and #30							; Bits5,4: mapper slot
	srl a
	srl a
	srl a
	srl a
	ld (var_mapslt),a
	ld a,b
	and #c0							; Bits7,6: megaram slot
	srl a
	srl a
	srl a
	srl a
	srl a
	srl a
	ld (var_megslt),a

; ############## Main loop

bucle_repaint_selection:
	ld   a, #ff						; Print selection
	call print_selection

bucle:
	ld   hl,#2b05					; Print Enable Mapper
	ld   a,(var_mapper)
	call print_on_off

	ld   hl,#2b07					; Print Enable Megaram
	ld   a,(var_megram)
	call print_on_off

	ld   hl,#2b09					; Print Ghost SCC
	ld   a,(var_ghtscc)
	call print_on_off

	ld   hl,#2b0b					; Print Enable Scanlines
	ld   a,(var_scanln)
	call print_on_off

	ld   hl,#3c05					; Print Mapper Slot
	call POSIT						; BIOS setCursor
	ld   a,(var_mapslt)
	add  a,#30
	call CHPUT						; BIOS printChar

	ld   hl,#3c07					; Print MegaRam Slot
	call POSIT						; BIOS setCursor
	ld   a,(var_megslt)
	add  a,#30
	call CHPUT						; BIOS printChar

	; Wait for a key
wait_for_a_key:
	ei
	halt
	call CHSNS						; BIOS keyStatus
	jr   z, wait_for_a_key
	call CHGET						; BIOS readChar
	or   a
	jr   z, wait_for_a_key

; ############## Keys handling

.key_lateral:
	sub  VT_RIGHT
	jr   z, .key_lateral_ok
	dec  a
	jr   nz, .key_up
.key_lateral_ok:
	ld   e, (ix+STRUCT_KEY_LATERAL)
	ld   d, (ix+STRUCT_KEY_LATERAL+1)
.new_selection:
	ld   a, 0						; Remove selection print
	call print_selection
	ld   ixl, e
	ld   ixh, d
	ld   (var_currentStruct), ix
	jr   bucle_repaint_selection

.key_up:
	dec  a
	jr   nz, .key_down
	ld   e, (ix+STRUCT_KEY_UP)
	ld   d, (ix+STRUCT_KEY_UP+1)
	jr   .new_selection

.key_down:
	dec  a
	jr   nz, .key_space
	ld   e, (ix+STRUCT_KEY_DOWN)
	ld   d, (ix+STRUCT_KEY_DOWN+1)
	jr   .new_selection

.key_space:
	ld   hl, bucle
	push hl
	dec  a
	ret  nz

	ld   l, (ix+STRUCT_SEL_ACTION)
	ld   h, (ix+STRUCT_SEL_ACTION+1)
	jp   (hl)

; ############## Actions

selected_mapper:
	ld hl, var_mapper
	call .selected_on_off
	or   a
	ret  nz
	ld   (var_mapslt), a
	ret

selected_megaRam:
	ld hl, var_megram
	call .selected_on_off
	or   a
	ret  nz
	ld   (var_megslt), a
	ret

selectedSlot1Ghost:
	ld hl, var_ghtscc
	jr .selected_on_off

selected_scanlines:
	ld hl, var_scanln

.selected_on_off:
	ld a,(hl)
	xor 1
	ld (hl),a
	ret

selected_mapperSlot:
	ld a,(var_megslt)
	ld b, a
	ld a,(var_mapslt)
.mp_nomeg:
	inc a
	cp b
	jr z,.mp_nomeg
	cp 4
	jr nz,.mp_no4
	xor a
.mp_no4:
	ld (var_mapslt),a
	ret

selected_megaRamSlot:
	ld  a,(var_mapslt)
	ld  b, a
	ld  a,(var_megslt)
.mr_nomap:
	inc a
	cp  b
	jr  z,.mr_nomap
	cp  4
	jr  nz,.mr_no4
	xor a
.mr_no4:
	ld  (var_megslt),a
	ret

selected_saveReset:
	pop  hl							; Remove ret to bucle
	call selected_saveExit
	di
	ld   a, #48						; Set I/O device to Goauld (#48)
	out  (#40),a
	ld   a, #80						; Bit 7: reset
	out  (#42), a
	ei
	ret

selected_saveExit:
	pop  hl							; Remove ret to bucle
	call config_var2byte
	di
	ld  a, #48						; Set I/O device to Goauld (#48)
	out (#40),a
	ld  a, b						; Set Goauld settings
	out (#41),a
	ei
	call INITXT						; BIOS clearScreen
	ld   bc, #000d					; Blink mode off
	jp   WRTVDP

config_var2byte:
	ld a,(var_mapper)				; Bit 0: mapper enable
	ld b,a
	ld a,(var_megram)				; Bit 1: megaram enable
	add a,a
	or b
	ld b,a
	ld a,(var_ghtscc)				; Bit 2: ghost scc enable
	add a,a
	add a,a
	or b
	ld b,a
	ld a,(var_scanln)				; Bit 3: scanlines enable
	add a,a
	add a,a
	add a,a
	or b
	ld b,a
	ld a,(var_mapslt)				; Bits5,4: mapper slot
	add a,a
	add a,a
	add a,a
	add a,a
	or b
	ld b, a
	ld a,(var_megslt)				; Bits7,6: megaram slot
	add a,a
	add a,a
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
	call CHPUT						; BIOS printChar
	jr print_string

; Set the cursor to L,H position and prints 'Off'/'On ' if A is 0 or not.
; Input    : H  - Y coordinate of cursor
;            L  - X coordinate of cursor
;            A  - Value to print (0:Off 1:On)
print_on_off:
	ld   b, a
	call POSIT						; BIOS setCursor
	ld   a, b
	ld   hl,offStr
	or   a
	jr   z,print_on_off_end
	ld   hl,onStr
print_on_off_end:
	jr   print_string

; Print the text of a struct
; Input    : IX - Struct address
print_struct:
	ld   l, (ix+STRUCT_POSXY+1)
	ld   h, (ix+STRUCT_POSXY)
	call POSIT						; BIOS setCursor
	ld   l, (ix+STRUCT_TEXT)
	ld   h, (ix+STRUCT_TEXT+1)
	jr   print_string

; Print the selection highlight on/off
; Input    : A  - 0:off #ff:on
print_selection:
	ld   ix, (var_currentStruct)
	ld   b, 0
	ld   c, (ix+STRUCT_SEL_LEN)
	ld   l, (ix+STRUCT_SEL_START)
	ld   h, (ix+STRUCT_SEL_START+1)
	jp   FILVRM


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


; ############## Structs

STRUCT_POSXY		equ		0
STRUCT_TEXT			equ		STRUCT_POSXY + 2
STRUCT_KEY_UP		equ		STRUCT_TEXT + 2
STRUCT_KEY_DOWN		equ		STRUCT_KEY_UP + 2
STRUCT_KEY_LATERAL	equ		STRUCT_KEY_DOWN + 2
STRUCT_SEL_START	equ		STRUCT_KEY_LATERAL + 2
STRUCT_SEL_LEN		equ		STRUCT_SEL_START + 2
STRUCT_SEL_ACTION	equ		STRUCT_SEL_LEN + 1

STRUCT_SIZE			equ		STRUCT_SEL_ACTION + 2	; Struct size

structs_start:
struct_EnableMapper:
	.db 21, 5
	.dw enableMapperStr
	.dw struct_SaveReset, struct_EnableMegaRam, struct_MapperSlot
	.dw #0800 + 4*10 + 2
	.db 4
	.dw selected_mapper

struct_EnableMegaRam:
	.db 21, 7
	.dw enableMegaRamStr
	.dw struct_EnableMapper, struct_Slot1GhostSCC, struct_MegaRamSlot
	.dw #0800 + 6*10 + 2
	.db 4
	.dw selected_megaRam

struct_Slot1GhostSCC:
	.db 21, 9
	.dw slot1GhostStr
	.dw struct_EnableMegaRam, struct_EnableScanlines, struct_Slot1GhostSCC
	.dw #0800 + 8*10 + 2
	.db 4
	.dw selectedSlot1Ghost

struct_EnableScanlines:
	.db 21, 11
	.dw enableScanlinesStr
	.dw struct_Slot1GhostSCC, struct_SaveExit, struct_EnableScanlines
	.dw #0800 + 10*10 + 2
	.db 4
	.dw selected_scanlines

struct_SaveExit:
	.db 21, 13
	.dw saveExitStr
	.dw struct_EnableScanlines, struct_SaveReset, struct_SaveExit
	.dw #0800 + 12*10 + 2
	.db 4
	.dw selected_saveExit

struct_SaveReset:
	.db 21, 15
	.dw saveResetStr
	.dw struct_SaveExit, struct_EnableMapper, struct_SaveReset
	.dw #0800 + 14*10 + 2
	.db 4
	.dw selected_saveReset

struct_MapperSlot:
	.db 54, 5
	.dw slotStr
	.dw struct_SaveReset, struct_MegaRamSlot, struct_EnableMapper
	.dw #0800 + 4*10 + 6
	.db 2
	.dw selected_mapperSlot

struct_MegaRamSlot:
	.db 54, 7
	.dw slotStr
	.dw struct_MapperSlot, struct_Slot1GhostSCC, struct_EnableMegaRam
	.dw #0800 + 6*10 + 6
	.db 2
	.dw selected_megaRamSlot

structs_end:
	.db 0


; ############## Variables

var_mapper: ds 1
var_megram: ds 1
var_ghtscc: ds 1
var_scanln: ds 1
var_mapslt: ds 1
var_megslt: ds 1

var_currentStruct: ds 2


; ############## MSX VT-52 Character Codes

VT_BEEP    equ	#07		; A beep sound
VT_RETURN  equ	#0d		; 13,"M"	; Carriage return
VT_RIGHT   equ	#1c		; 27,"C"	; Cursor right
VT_LEFT    equ	#1d		; 27,"D"	; Cursor left
VT_UP      equ	#1e		; 27,"A"	; Cursor up
VT_DOWN    equ	#1f		; 27,"B"	; Cursor down
VT_SPACE   equ	#20		; Space
VT_CLRSCR  equ	#0c		; 27,"E"	; Clear screen:	Clears the screen and moves the cursor to home
VT_HOME    equ	#0b		; 27,"H"	; Cursor home:	Move cursor to the upper left corner.

