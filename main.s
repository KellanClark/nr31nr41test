
include "hardware.inc"

SECTION "Header", ROM0[$100]

	di
	jp Start
	ds $150 - $104, 0

SECTION "Start", ROM0

Start:
	; Set stack pointer
	ld sp, $FFFC

	; Set variables
	xor a
	ldh [hCharX], a
	ld hl, hTileMapPtr
	; ld [hl], bc
	ld bc, $9800
	ld [hl], c
	inc hl
	ld [hl], b

	call WaitVBlank

	; Turn off LCD
	xor a ; ld a, LCDCF_OFF
	ldh [rLCDC], a

	; Set palette
	ld a, %11100100
	ldh [rBGP], a

	; Set scroll
	ld a, $78 ; Start of tilemap is bottom row of tiles
	ldh [rSCY], a
	xor a
	ldh [rSCX], a

	; Copy hex characters to memory
	ld hl, HexChars
	ld c, $80
:	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, c
	cp $80 + 16
	jr nz, :-

	; Clear tile map
	ld bc, $0800
	ld hl, $9800
	call Memset

	; Copy tiles to VRAM
	ld bc, $1000
	ld de, TileData
	ld hl, $8000
	call Memcpy

	ld a, $80
	ldh [rNR52], a

	; Test NR31 with $00
	ld hl, WritingMsg
	call PrintString
	xor a
	call PrintHex
	ld hl, NR31Msg
	call PrintString
	xor a
	ldh [rNR31], a
	ld a, [rNR31]
	call PrintHex

	; Test NR31 with $FF
	ld hl, WritingMsg
	call PrintString
	ld a, $FF
	call PrintHex
	ld hl, NR31Msg
	call PrintString
	ld a, $FF
	ldh [rNR31], a
	ld a, [rNR31]
	call PrintHex

	ld a, "\n"
	call PrintChar

	; Test NR41 with $00
	ld hl, WritingMsg
	call PrintString
	xor a
	call PrintHex
	ld hl, NR41Msg
	call PrintString
	xor a
	ldh [rNR41], a
	ld a, [rNR41]
	call PrintHex

	; Test NR41 with $FF
	ld hl, WritingMsg
	call PrintString
	ld a, $FF
	call PrintHex
	ld hl, NR41Msg
	call PrintString
	ld a, $FF
	ldh [rNR41], a
	ld a, [rNR41]
	call PrintHex

	; Turn LCD back on, disable window/objects, and set map/data areas
	ld a, %10010001
	ldh [rLCDC], a

	halt

; Loop until line 144 is reached (start of VBlank)
; A = [corrupted]
WaitVBlank:
	ldh a, [rLY]
	cp $90
	jr nz, WaitVBlank
	ret

; Set region of memory to specific value
; A = value
; BC = number of bytes to set
; HL = start of memory region
Memset:
	ld [hl+], a
	dec c
	jr nz, Memset
	dec b
	jr nz, Memset
	ret

; Copy one region of memory to another
; A = [corrupted]
; BC = number of bytes to copy
; DE = start of source region
; HL = start of destination region
Memcpy:
	ld a, [de]
	ld [hl+], a
	inc de
	dec c
	jr nz, Memcpy
	dec b
	jr nz, Memcpy
	ret

; Print an ASCII character to the screen and scroll if needed
; A = character
; DE = [corrupted]
; HL = [corrupted]
PrintChar:
	; Retrieve pointer (stored in DE) to location in tile map
	ld hl, hTileMapPtr
	; ld de, [hl]
	ld e, [hl]
	inc hl
	ld d, [hl]
	dec hl

	; Check for newline character
	cp "\n"
	jr z, .nextLine
.normalChar:
	ld [de], a ; Print character on screen

	; Update X and check if end of line
	inc de
	ldh a, [hCharX]
	inc a
	cp 20
	jr nz, .done
.nextLine:
	; Move to next line
	ld a, e
	and $E0 ; Beginning of line
	add 32 ; Add a line
	ld e, a
	ld a, d
	adc 0
	cp $9c ; Cycle to beginning of tile map
	jr nz, .next
	ld a, $98
	ld e, 0
.next:
	ld d, a
	ldh a, [rSCY] ; Move scroll
	add 8
	ldh [rSCY], a
	xor a
.done:
	; Store new values and return
	ldh [hCharX], a
	ld [hl], e
	inc hl
	ld [hl], d
	ret

; Print an null terminated string of ASCII characters to the screen
; A = [corrupted]
; DE = [corrupted]
; HL = start location of string
PrintString:
	ld a, [hl+]
	cp 0
	jr z, .done
	push hl
	call PrintChar
	pop hl
	jr PrintString
.done:
	ret

; Prints a byte onto the screen in hexadecimal
; A = character
; C = [corrupted]
; DE = [corrupted]
; HL = [corrupted]
PrintHex:
	push af
	; Top nibble
	swap a
	and $F
	or $80
	ld c, a
	ldh a, [c]
	call PrintChar
	; Bottom nibble
	pop af
	and $F
	or $80
	ld c, a
	ldh a, [c]
	call PrintChar
	ret

WritingMsg: db "\nWriting $", 0
NR31Msg: db " to NR31\nRead $", 0
NR41Msg: db " to NR41\nRead $", 0

HexChars: db "0123456789ABCDEF"

TileData:
INCBIN "tiles.bin"

SECTION "HRAMVariables", HRAM

hHexChars: ds 16
hCharX: ds 1
hTileMapPtr: ds 2
