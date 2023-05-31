INCLUDE "../pong-gb/hardware.inc"

Section "header", ROM0[$100]
	
	jp Begin

	ds $150 - @, 0 ;Make room for header

	Begin:
		call WaitVBlank
		; Turn LCD off
		ld a, 0
		ld [rLCDC], a

		; Copy the tile data
		ld de, Tiles
		ld hl, $9000
		ld bc, TilesEnd - Tiles
		call Memcopy
		
		; Copy the tilemap data
		ld de, TileMap
		ld hl, $9800
		ld bc, TileMapEnd - TileMap
		call Memcopy

		; Turn the LCD on
		ld a, LCDCF_ON | LCDCF_BGON
		ld [rLCDC], a

		; Set background palette
		ld a, PAL1
		ld [rBGP], a

		ld a, 0
		ld [wFrameCounter], a
		ld [wFrameCounter2], a

MainLoop:
	call WaitVBlank
	call WaitVBlankOver
	call TopDownEffect
	jp MainLoop



		;Top down wave effect
		TopDownEffect:
			ld a, PAL2
			ld [rBGP], a

			ld a, [wFrameCounter]
			
			; If all lines have changed pallete, start second part
			cp a, 143
			jp nc, .part2

			add a, 1
			ld b, a

			; Wait until line to be drawn hasn't change pallete
			.loop1:
				ld a, [rLY]
				cp b
				jp c, .loop1
			
			ld a, PAL1
			ld [rBGP], a
			ld a, [wFrameCounter]
			inc a
			ld [wFrameCounter], a
			ret
			; Same effect but scan lines are changed back to normal
			.part2:
				ld a, PAL1
				ld [rBGP], a
				ld a, [wFrameCounter2]
				add a, 1
				ld b, a

				.loop2:
					ld a, [rLY]
					cp b
					jp c, .loop2

				ld a, PAL2
				ld [rBGP], a
				ld a, [wFrameCounter2]
				inc a
				ld [wFrameCounter2], a
			ret






		Tiles:
		ds  16, $FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

		TilesEnd:

		TileMap:

		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		TileMapEnd:

	; Copy data from one place to another
	; @param de: source
	; @param hl: destination
	; @param bc: byteCount
	Memcopy:
		ld a, [de]
		ld [hli], a
		inc de
		dec bc
		ld a, b
		or a, c
		jp nz, Memcopy
		ret

	; Wait for VBlank
	WaitVBlank:
		ld a, [rLY]
		cp 144
		jp c, WaitVBlank
		ret

	WaitVBlankOver:
	ld a, [rLY]
	cp 0
	jp nz, WaitVBlankOver
	ret

Section "Counter", WRAM0
wFrameCounter: db
wFrameCounter2: db

DEF PAL1 EQU %11111111
DEF PAL2 EQU %00000000
