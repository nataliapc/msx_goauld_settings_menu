org #7d40
	call  CHSNS
	ret z
	call read_char
	cp a,#67
	ret nz

	;load variables in ram
	ld a,(var1_init)
	ld (var1),a
	ld a,(var2_init)
	ld (var2),a
	ld a,(var3_init)
	ld (var3),a
	ld a,(var4_init)
	ld (var4),a

	;print menu
	ld hl,#0101
	call set_cursor
	ld hl,menu
	call print_string

	;main loop
bucle:
	;print var1
	ld hl,#1402
	call set_cursor
	ld a,(var1)
	ld hl,off
	or a
	jr z,sigue1
	ld hl,on
sigue1:
	call print_string

	;print var2
	ld hl,#1403
	call set_cursor
	ld a,(var2)
	ld hl,off
	or a
	jr z,sigue2
	ld hl,on
sigue2:
	call print_string

	;print var3
	ld hl,#1404
	call set_cursor
	ld a,(var3)
	ld hl,off
	or a
	jr z,sigue3
	ld hl,on
sigue3:
	call print_string

	;print var4
	ld hl,#1405
	call set_cursor
	ld a,(var4)
	add a,#30
	call print_char

	call  CHSNS
	jr z, bucle
	call read_char
	or a
	jr z, bucle

	cp a,#31
	jr nz,tecla2
	
	ld a,(var1)
	xor 1
	ld (var1),a
	jr bucle

tecla2:	
	cp a,#32
	jr nz,tecla3
	
	ld a,(var2)
	xor 1
	ld (var2),a
	jr bucle

tecla3:
	cp a,#33
	jr nz,tecla4
	
	ld a,(var3)
	xor 1
	ld (var3),a
	jr bucle_largo

tecla4:
	cp a,#34
	jr nz,tecla5
	
	ld a,(var4)
	inc a
	cp a,4
	jr nz,no4
	xor a
no4:
	ld (var4),a
	jr bucle_largo	

tecla5:
	cp a,#35
	jr nz,tecla6
	call get_config
	out (#41),a
	ret

tecla6:
	cp a,#36
	jr nz,bucle_largo
	call get_config
	or #80
	out (#41),a
	ret	

bucle_largo:
	jp bucle

get_config:
	ld a,(var1)
	ld b,a
	ld a,(var2)
	sla a
	or b
	ld b,a
	ld a,(var3)
	sla a
	sla a
	sla a
	or b
	ld b,a
	ld a,(var4)
	sla a
	sla a
	sla a
	sla a
	or b
	ret

;msx
print_char equ #00a2
set_cursor equ #00C6
read_char equ #009f
CHSNS equ #009C

;amstrad
;print_char equ #bb5a
;set_cursor equ #bb75
;read_char equ #bb09

print_string:
	ld a,(hl)
	cp 255
	ret z
	inc hl
	call print_char
	jr print_string


var1_init: db 1
var2_init: db 1
var3_init: db 1
var4_init: db 0

var1 equ #8000
var2 equ #8001
var3 equ #8002
var4 equ #8003


menu: db "Goauld Config",#0d,#0a,"1-Enable Mapper",#0d,#0a,"2-Enable Megaram",#0d,#0a,"3-Enable Scanlines",#0d,#0a,"4-Mapper Slot",#0d,#0a,"5-Save & Exit",#0d,#0a,"6-Save & Reset",255
on: db "On ",255
off: db "Off",255