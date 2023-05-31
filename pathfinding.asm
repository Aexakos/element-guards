INCLUDE "hardware.inc"

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

		; Copy the object tile data
		ld de, TilesEnd
		ld hl, $8000
		ld bc, TilesEnd2 - TilesEnd
		call Memcopy

		ld a, 0
		ld b, 160
		ld hl, _OAMRAM
		ClearOAM:
			ld [hli], a
			dec b
			jp nz, ClearOAM

		ld hl, _OAMRAM
		ld a, 64 + 16
		ld [hli], a
		ld a, 8
		ld [hli], a
		ld a, 0
		ld [hli], a
		ld [hl], a

		ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
		ld [rLCDC], a

		ld a, %11110100
		ld [rBGP], a
		ld a, %11100100
		ld [rOBP0], a

		; Initiate variables
		ld a, 0
		ld [wStartTile], a
		ld [wGoalTile], a
		ld [wQueuedTiles], a
		ld [wVisitedTiles], a
		ld [wVisitedTiles + 1], a

		ld a, [STARTX]
		ld b, a
		ld a, [STARTY]
		ld c, a
		call SetStartTile
		ld b, ENDX
		ld c, ENDY
		call SetGoalTile
		call WaitVBlank
		call BFSPathing
	MainLoop:
		
		jp MainLoop

	; Converts pixels into tile coords and loads them into wStartTIle
	; @param b: X (pixels)
	; @param c: Y (pixels)
	; @return wStartTile: tile coordinates
	SetStartTile:

		; Get starting tile cordinates
		ld a, b
		sub a, 8
		ld b, a
		ld a, c
		sub a, 16
		ld c, a
		call GetTileCords
		ld a, h
		ld b, a
		ld a, l
		ld c, a
		ld hl, wStartTile
		ld a, b
		ld [hli], a
		ld a, c
		ld [hl], a

		ret

	; Converts pixels into tile coords and loads them into wGoalTIle
	; @param b: X (pixels)
	; @param c: Y (pixels)
	; @return wGoalTile: tile coordinates
	SetGoalTile:

		; Get goal tile cordinates
		ld a, b
		sub a, 8
		ld b, a
		ld a, c
		sub a, 16
		ld c, a
		call GetTileCords
		ld a, h
		ld b, a
		ld a, l
		ld c, a
		ld hl, wGoalTile
		ld a, b
		ld [hli], a
		ld a, c
		ld [hl], a

		ret

	; Uses the breadth-first search algorithm for pathfinding
	; @parameter: wStartTile
	; @parameter: wGoalTile
	; @return: wPathDirections (==XX_XX_.._XX_00, where x: 01=R, 02=D, 03=L, 04=P) 
	BFSPathing:

		; Add starting tile and null sequence to queue
		ld hl, wStartTile
		ld a, [hli]
		ld b, a
		ld a, [hl]
		ld c, a
		ld hl, wQueuedTiles
		ld a, b
		ld [hli], a
		ld a, c
		ld [hli], a
		ld a, 0
		ld [hli], a
		ld [hl], a
		
		; Set queued tile pointer to current tile
		dec hl
		dec hl
		dec hl

		; Pathfinding loop
		; @param hl, queued tiles address
		CheckTile:
			; Load current tile coords in de
			ld a, [hli]
			ld d, a
			ld a, [hli]
			ld e, a
			
			; Decrement hl to current tile coords address
			dec hl
			dec hl

			; Load current tile coords address in bc
			ld a, h
			ld b, a
			ld a, l
			ld c, a
	
			.wait
				ldh a, [rSTAT]
				and a, STATF_BUSY
			 jp nz, .wait

		; Checks if tile (de) is a valid road
		; @param de: current tile cords
		; @return hl: adress of current tile in tilemap
		; @return z: of tile is road
		IsRoad:
			ld hl, $9800
			add hl, de
			ld a, [hl]
			cp $01

			; If tile is not road, return false
			jp nz, False

			ld hl, wVisitedTiles

			;Iterates over VisitedTiles array
			.loop
				
				ld a, [hl]
				cp d
				jp z, .CheckVisited

				; Checks if pointer is over escape sequence and returns z
				.CheckNull:
					
					ld a, [hl]
					inc hl
					inc hl
					cp 0
					jp nz, .loop
					dec hl
					ld a, [hl]
					inc hl
					cp 0
					jp nz, .loop

					; Set pointer before null sequence and exit .loop
					dec hl
					dec hl
					jp .loopExit
				
				; Checks if current tile is visited and returns nz
				.CheckVisited:
					inc hl
					ld a, [hl]
					dec hl
					cp e
					jp nz, .CheckNull
					
					ld a, 1
					cp 0
					jp .loopExit

			.loopExit:

			; If current tile is in visited(f==nz), return false
			jp nz, False

			; Set current tile as visited and add null sequence
			ld a, d
			ld [hli], a
			ld a, e
			ld [hli], a
			ld a, 0
			ld [hli], a
			ld [hli], a
			
			ld hl, wGoalTile
			ld a, d
			cp [hl]
			jp nz, CheckGoalEnd
			inc hl
			ld a, e
			cp [hl]
			jp nz, CheckGoalEnd
			
			jp GoalReached

			CheckGoalEnd:

			; Loads tile cords address from bc to hl
			ld a, b
			ld h, a
			ld a, c
			ld l, a

			; Sets QueueEndIndex to 0
			ld a, 0
			ld c, a

			   ; de: tile cords// hl: ...-,curTile,
			; Iterates through QueuedTiles until it finds null sequence
			; hl: address
			; c: QueueEndIndex (byte offset)
			FindQueueEnd:
				; Increase queue end index
				ld a, c
				inc a
				ld c, a

				ld a, [hli]
				cp 0
				jp z, CheckQueueEnd

				inc hl
				; Increase queue end index
				ld a, c
				inc a
				ld c, a

				jp FindQueueEnd

				CheckQueueEnd:
					; Increase queue end index
					ld a, c
					inc a
					ld c, a

					ld a, [hli]
					cp 0
					jp nz, FindQueueEnd

					; Set pointer before null sequence and set de to 0
					dec hl
					dec hl					

			; Push 4 adjacent tiles in queue
			; hl: address
			; de: cords

			; Push right tile
			ld a, 1
			add a, e
			ld e, a
			ld a, d
			adc a, 0
			ld d, a
			ld [hli], a
			ld a, e
			ld [hli], a

			; Push left tile 
			sub a, 1 + 1
			ld e, a
			ld a, d
			sbc a, 0
			ld d, a
			ld [hli], a
			ld a, e
			ld [hli], a

			; Push down tile
			ld a, 32 + 1
			add a, e
			ld e, a
			ld a, d
			adc a, 0
			ld d, a
			ld [hli], a
			ld a, e
			ld [hli], a

			; Push up tile
			sub a, 32 + 32
			ld e, a
			ld a, d
			sbc a, 0
			ld d, a
			ld [hli], a
			ld a, e
			ld [hli], a

			; Push null sequnce
			ld a, 0
			ld [hli], a
			ld [hli], a

			; Increment queue end index
			ld a, c
			add a, 10 - 4
			ld c, a

			; Set Queue pointer after current tile (hl = hl - c)
			ld a, l
			sub a, c
			ld l, a
			ld a, h
			sbc a, 0
			ld h, a

			jp CheckTile

			False:
			
			; Set bc(:current tile address) to hl and increment to next tile
			ld a, b
			ld h, a
			ld a, c
			ld l, a

			inc hl
			inc hl
				
			jp CheckTile

			GoalReached:

			; Load visited tiles into bc
			ld hl, wVisitedTiles
			ld a, h
			ld b, a
			ld a, l
			ld c, a

			; Add path directions in wPathDirections
			; @param: bc, visited tiles address
			PathDirectionsLoop:
				

				; Load bc into hl and [bc+2] into de, set hl to current tile lowbyte
				ld a, b
				ld h, a
				ld a, c
				ld l, a
				inc hl
				inc hl
				ld d, [hl]
				inc hl
				ld e, [hl]

				; If NextTile==NULL, return

				ld a, d
				cp 0
				jp nz, .NullCheckEnd

				ld a, e
				cp 0
				jp nz, .NullCheckEnd

				ret

				.NullCheckEnd:

				dec hl
				dec hl

				; Subtract next tile from current tile
				ld a, e
				sub [hl]
				dec hl
				ld e, a
				ld a, d
				sbc [hl]
				inc hl
				inc hl
				ld a, e

				; Check direction
				cp 1
				jp z, .HigherX
				cp -1
				jp z, .LowerX
				cp 32
				jp z, .HigherY

				.LowerY:
					; Set current tile coords address to bc
					ld a, h
					ld b, a
					ld a, l
					ld c, a
					
					; Subtract wVisitedTiles from bc and load difference to hl
					ld hl, wVisitedTiles
					ld a, c
					sub l
					ld l, a
					ld a, b
					sbc a, h
					ld h, a

					; Divide difference by 2 and set it to de
					srl h
					rr l
					ld a, h
					ld d, a
					ld a, l
					ld e, a
					
					; Set hl to next direction adress
					ld hl, wPathDirections
					add hl, de
					dec hl

					; Set direction to PathDirections and null byte
					ld a, 4
					ld [hli], a
					ld a, 0
					ld [hl], a

					jp PathDirectionsLoop

				.HigherX:
					; Set current tile coords address to bc
					ld a, h
					ld b, a
					ld a, l
					ld c, a

					; Subtract wVisitedTiles from bc and load difference to hl
					ld hl, wVisitedTiles
					ld a, c
					sub l
					ld l, a
					ld a, b
					sbc a, h
					ld h, a

					; Divide difference by 2 and set it to de
					srl h
					rr l
					ld a, h
					ld d, a
					ld a, l
					ld e, a
					
					; Set hl to next direction adress
					ld hl, wPathDirections
					add hl, de
					dec hl

					; Set direction to PathDirections and null byte
					ld a, 1
					ld [hli], a
					ld a, 0
					ld [hl], a

					jp PathDirectionsLoop

				.LowerX:
					; Set current tile coords address to bc
					ld a, h
					ld b, a
					ld a, l
					ld c, a

					; Subtract wVisitedTiles from bc and load difference to hl
					ld hl, wVisitedTiles
					ld a, c
					sub l
					ld l, a
					ld a, b
					sbc a, h
					ld h, a
					
					; Divide difference by 2 and set it to de
					srl h
					rr l
					ld a, h
					ld d, a
					ld a, l
					ld e, a

					; Set hl to next direction adress
					ld hl, wPathDirections
					add hl, de
					dec hl

					; Set direction to PathDirections and null byte
					ld a, 3
					ld [hli], a
					ld a, 0
					ld [hl], a

					jp PathDirectionsLoop

				.HigherY:
					; Set current tile coords address to bc
					ld a, h
					ld b, a
					ld a, l
					ld c, a

					; Subtract wVisitedTiles from bc and load difference to hl
					ld hl, wVisitedTiles
					ld a, c
					sub l
					ld l, a
					ld a, b
					sbc a, h
					ld h, a
					
					; Divide difference by 2 and set it to de
					srl h
					rr l
					ld a, h
					ld d, a
					ld a, l
					ld e, a
					
					; Set hl to next direction adress
					ld hl, wPathDirections
					add hl, de
					dec hl

					; Set direction to PathDirections and null byte
					ld a, 2
					ld [hli], a
					ld a, 0
					ld [hl], a	

					jp PathDirectionsLoop

	; Returns tile position in tilemap based on pixels
	; @param b: Xpixel
	; @param c: Ypixel
	; @return hl: tile cords (X + Y * 32)
	GetTileCords:
		ld a, c
		and a, %1111100
		ld l, a
		ld h, 0
		add hl, hl
		add hl, hl
		ld a, b
		srl a
		srl a
		srl a
		add a, l
		ld l, a
		adc a, h
		sub a, l
		ld h, a
		ret

 	; Wait for VBlank
	WaitVBlank:
		ld a, [rLY]
		cp 144
		jp c, WaitVBlank
		ret
	; Wait for not VBlank
	WaitNoVBlank:
		ld a, [rLY]
		cp 144
		jp nc, WaitNoVBlank
		ret

	Memcopy:
		ld a, [de]
		ld [hli], a
		inc de
		dec bc
		ld a, b
		or a, c
		jp nz, Memcopy
		ret


		Tiles:
			dw `33333333
			dw `33333333
			dw `33333333
			dw `33333333
			dw `33333333
			dw `33333333
			dw `33333333
			dw `33333333
			dw `00000000
			dw `00000000
			dw `00000000
			dw `00000000
			dw `00000000
			dw `00000000
			dw `00000000
			dw `00000000

		TilesEnd:
			dw `00000000
			dw `02222220
			dw `02222220
			dw `02222220
			dw `02222220
			dw `02222220
			dw `02222220
			dw `00000000

		TilesEnd2:

		TileMap:

			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $01, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $00, $01, $00, $01, $01, $01, $01, $01, 0,0,0,0,0,0,0,0,0,0,0,0
			db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $01, $00, $01, $01, $01, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
			db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0

		TileMapEnd:

DEF STARTY EQU _OAMRAM
DEF STARTX EQU _OAMRAM+1

DEF ENDX EQU 160
DEF ENDY EQU 72

SECTION "Booleans", WRAM0

Section "Pathfinding Arrays", WRAM0
wVisitedTiles: ds 432
wQueuedTiles: ds 432
wPathDirections: ds 32

SECTION "Pathfinding Variables", WRAM0
wStartTile: dw
wGoalTile: dw
