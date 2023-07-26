;BOOT.COM -- CP/M-65 SD BOOT UTILITY JC Version
;BY D. LAUSBERG	 (C)1988
;V1.0	21.07.23
;V1.1	26.07.23	;$CC00 version

VERSION	= $11

;SYSTEM CONSTANTS
DMA	=  $FE
DPH	=  $F8
FCB1	=  $F6
FCB2	=  $F4
BDOS	=  $F0
INBUF	=  $EC
CCPV	=  $DE

TPA	= $200
CCP	= $CC00
BIOS	= $D800
ROM_MONITOR = $E000	;Monitor cold start

PRTCHR	= $F80C

;Zero Page adresses

DRIVE	= $10
ERRNO	= $11
SEC	= $12

SD_CMD	= $81	;CMD Byte
SD_PB3  = $82   ;Parameter Byte 3
SD_PB2	= $83   ;Parameter Byte 2
SD_PB1  = $84   ;Parameter Byte 1
SD_PB0	= $85   ;Parameter Byte 0
SD_CRC	= $86   ;CRC Byte
PLBA	= $87	;LBA Pointer

XBUF	= $8A
YBUF	= $8B
TEMP	= $8C   ;temp storage
SECS	= $8D	;sec adr
BLKBUF	= $92

;--- VIA 6522 adresses
;SPI driver  Mode 0
;uses VIA DRB
;Bit 7	MISO
;BIT 6	MOSI
;Bit 0	CLK

DRB	= $F400
DDRB	= $F402
PCR	= $F40C

;--- SD Command Constants 

CMD0	= $40		; Reset SD-Card
CMD1	= CMD0 + 1	; Initialize MMC/SDC
CMD8	= CMD0 + 8	; Check voltage range
CMD13	= CMD0 + 13	;
CMD16	= CMD0 + 16	; Change block size
CMD17	= CMD0 + 17	; Read single block
CMD24	= CMD0 + 24	; Write single block
CMD55	= CMD0 + 55	; Application command prefix
CMD58	= CMD0 + 58	; Get OCR
ACMD41	= CMD0 + 41	; Initialize SDC

DATA_TOKEN	= $FE	; SD-Card Data Token Read Block

;--- constants ---

SYSSCS	= 32		;SYSTEM sectors CPM-65
DIRSCS	= 32		;directory sectors CPM-65

;BDOS COMMANDS

CBOOT	= $00
CBIOS	= $1A

;BIOS COMMANDS

MOUNT	= $11

;CONTROL CODES

EOT	= $00
BS	= $08
LF	= $0A
CLS	= $0C
CR	= $0D
SPACE	= $20
SEMI	= $3B

;ERROR CODES

INVDRV	= $85
WRT_PROT = $86
SD_CHNG	= $87
NO_SD	= $88


	ORG TPA

	JMP BOOT

;---  CP/M-65 BIOS disk image table  -------------------

IMGTAB	DB $22,$0A,$00,$00	;Base LBA address of disk images mounted
	DS 3*4,$00
IMGSTAT	DB $FF,$00,$00,$00	;Flag $FF valid image, $00 no image
SD_TYPE	DB 0			;SD Card Type

;--- buffer for SD CARD

LBA	DS 4,0		;LSB ... MSB
LBA_B	DS 4,$FF
LBA_F	DB $00		;LBA FLAG BIT7 = dirty

;---  MESSAGES  -----------------------------

BOOTM	DB CR,LF,'CP/M-65 for JC-II Bootstrap Loader V'
	DB VERSION/16+$30,'.',VERSION*$1000/$1000+$30,CR,LF,EOT
ERRM	DB CR,LF,'BOOT failed',CR,LF,EOT

;--------------------------------------------

BOOT	LDY #3			;set LBA to current file
BOOT3	LDA IMGTAB,Y
	STA LBA,Y
	DEY
	BPL BOOT3
	LDA #$FF
	STA IMGSTAT		;make A: valid
	LDA #0
	STA DRIVE
	JSR INCLBA		;CCP starts in block 1
	JSR SPI_INIT		;initialize SPI
	JSR SD_INIT		;initialize SD card
	BCC B_ERR

BOOT2	LDA #CCP		;and boot it
	STA BLKBUF
	LDA #CCP/256
	STA BLKBUF+1
BOOT1	LDX #LBA
	LDY #LBA/256
	JSR SD_RD_LBLK		;read 512 bytes from SD to CCP
	BCC B_ERR
	JSR INCLBA		;LBA=LBA+1
	LDA BLKBUF+1
	CMP #ROM_MONITOR/256	;all sector read?
	BCC BOOT1
	LDY #0
BOOT5	LDA BOOTM,Y		;print boot message
	BEQ BOOT6
	JSR PRTCHR
	INY
	BNE BOOT5

BOOT6	LDX #4
BOOT7	LDA IMGTAB-1,X		;set LBA table in BIOS
	STA 0,X
	DEX
	BNE BOOT7
	STX 0
	TXA			;always 0 -> A:
	JSR MOUNT*3+BIOS	;BIOS MOUNT command
	BCS B_ERR
	JMP BIOS		;COLD BOOT

B_ERR	LDY #0
BOOT4	LDA ERRM,Y		;print error message
	BEQ BOOT_X
	JSR PRTCHR
	INY
	BNE BOOT4

BOOT_X	LDX #CBOOT		;and fall back to CPM-65
	JMP BDOS


INCLBA	LDX #0			;LBA = LBA+1
INCLBA1	INC LBA,X
	BNE INCLBAX
	INX
	CPX #4
	BCC INCLBA1
INCLBAX	RTS


; *****************************************************************************
; Read Single Data Block from Logical Address to Std. Block Buffer
; Input:  X,Y = Ptr[LO:HI] to 32 Bit LBA Address
; Output: C = 0 Error, C = 1 Data OK
;	  A = Error Code
; *****************************************************************************

SD_RD_LBLK_BUF	JSR	INIT_BLKBUF		; set pointer to block buffer
						; fall through to sd_rd_lblk

; *****************************************************************************
; Read Single Data Block from Logical Address
; Input:  X,Y = Ptr[LO:HI] to 32 Bit LBA Address
;	  BLKBUF,BLKBUFH = 16 Bit Destination Address
; Output: C = 0 Error, C = 1 Data OK
;	  A = Error Code
; *****************************************************************************

SD_RD_LBLK	JSR	LOAD_LBA		; convert LBA CMD ADR
						; fall through to sd_rd_blk

; *****************************************************************************
; Read Single Data Block
; Input:  SD_PB3..SD_PB0 = 32 Bit Command Block Address
;         BLKBUF,BLKBUFH = 16 Bit Destination Address
; Output: C = 0 Error, C = 1 Read OK
;	  A = Error Code
; *****************************************************************************

SD_RD_BLK	LDA	#CMD17			; send CMD17 (blk read)
		JSR	SD_SEND_BLK_CMD
		LDA	#DATA_TOKEN
		JSR	SD_WAIT_TOKEN		; wait for data token $FE
		CMP	#$FE			; is card ready for block read?
		CLC
		BNE	SD_RD_END		; did not receive data token, exit with C = 0
		LDX	#$01			; initialize page counter
		LDY	#$00			; initialize byte counter
SD_RD_BLK0	STY YBUF
		JSR	SPI_BIN		; read a byte
		LDY YBUF
		STA	(BLKBUF),Y		; and store it into the block buffer
		INY				; increment destination pointer
		BNE	SD_RD_BLK0		; pointer overflow? No, read next byte
		INC	BLKBUF+1			; yes, increment block buffer page
		DEX
		BPL	SD_RD_BLK0		; two pages read? no, read next byte
		INX
SD_RD_BLK1	JSR	SPI_BIN		; yes, read 3 more bytes (CRC H, CRC L, dummy)
		INX
		CPX	#$03			; all 3 bytes read?
		BNE	SD_RD_BLK1		; no, read next byte
		SEC				; yes, all data read, set C = 1
SD_RD_END	RTS

; *****************************************************************************
; Send Block Read or Write Command
; Input :  A = Command (CMD17,CMD24)
; Output : -
; *****************************************************************************

SD_SEND_BLK_CMD	JSR	SD_SEND_CMD
		BNE	SD_RESP_ERR		; response <> 0 check error type
		LDA	#DATA_TOKEN
		RTS

; *****************************************************************************
; Check Error
; *****************************************************************************

SD_RESP_ERR	AND	#$01			; is card in idle mode?
		BEQ	SD_DISK_RW		; no, print error
		JSR	SD_INIT			; yes, maybe card changed, reset
		BCS	SD_DISK_CHNG
SD_NO_DISK	LDA	#$80
		RTS

SD_DISK_RW	LDA	#$86
		CLC
		RTS

SD_DISK_CHNG	LDA	#$87
		CLC
		RTS


; *****************************************************************************
; Load Logical Block Address into Command Address.
; Swap Endian and Shift Bits if Desired
; Input:  X,Y = Ptr[LO:HI] to 32 Bit LBA Address
; Output: ADR in SD_PB3..SD_PB0
; *****************************************************************************

LOAD_LBA	STX	PLBA
		STY	PLBA+1
		LDX	#$04
		LDY	#$00
		LDA	SD_TYPE
		BNE	BLK_MODE
		CLC
		TYA
                STA	SD_CMD,X
		DEX
BIT_MODE	LDA	(PLBA),Y
		ROL	A
                STA	SD_CMD,X
		INY
		DEX
		BNE	BIT_MODE
		RTS
BLK_MODE	LDA	(PLBA),Y
		STA	SD_CMD,X
		INY
		DEX
		BNE	BLK_MODE
		RTS

; *****************************************************************************
; Initialize SD-Card
; Output: C = 1 Init OK, C = 0 Error
; *****************************************************************************

SD_INIT	LDA #$00
	STA SD_TYPE
	JSR SD_RESET		; reset SD-Card
	CMP #$01		; SD-Card present?
	BNE SDC_NOT_FOUND	; invalid response, no usable card found
	JSR SD_GET_VERS		; get SD-Card version
	CMP #$05		; seems to be a version 1 card
	BEQ INIT_SD0		; so just try to initialize it
	CMP #$AA		; version 2 cards should response with $(01)AA
	BNE SDC_NOT_FOUND	; invalid response, no usable card found
	LDA #$40		; try ACMD41($40000000) init (SD Ver. 2+)
	BNE INIT_SD1

INIT_SD0 LDA #$00		; try ACMD41($00000000) init (SD Ver. 1)
INIT_SD1 JSR SD_CLEAR_CMD	; prepare for new command
	STA SD_PB3
INIT_SD2 LDA #CMD55		; send prefix CMD55 (application cmd)
	JSR SD_SEND_CMD
	CMP #$01
	BNE SDC_NOT_FOUND	; invalid response, no usable card found
	LDA #ACMD41		; send ACMD41 (initialize)
	JSR SD_SEND_CMD
	BEQ INIT_SD3		; response = 0 means card waked up,
	CMP #$01		; card still idle?
	BEQ INIT_SD2		; yes, try again
	BNE SDC_NOT_FOUND	; no, invalid response, no usable card found
INIT_SD3 LDA SD_PB3		; Ver. 2+ Card?
	BEQ INIT_SD4		; no, just set block size
	JSR SD_CLEAR_CMD	; prepare for new command
	LDA #CMD58		; send CMD58 (get OCR)
	JSR SD_SEND_CMD
	BNE SDC_NOT_FOUND	; invalid response, no usable card found
	JSR SD_WAIT_RESP3	; wait for OCR response
	LDA SD_PB3	 	; Test Bit 30
	AND #$40	 	; 1 if SDHC/SDXC card, 0 else
	STA SD_TYPE	 	; set type $00 Byte mode, $40 LBA mode
INIT_SD4 JSR SD_CLEAR_CMD		; prepare for new command
	LDA #$02	 	; set blocksize to 512 byte
	STA SD_PB1
	LDA #CMD16		; send CMD16 (set block size)
	JSR SD_SEND_CMD
	BNE SDC_NOT_FOUND ; invalid response, no usable card found
	SEC 	 	; everything gone well, set carry
	RTS

SDC_NOT_FOUND
	LDA #$88
	CLC  		; something went wrong, clear carry
	RTS 		; to signal error

; *****************************************************************************
; Get SD-Card Version
;  ****************************************************************************
SD_GET_VERS 
	LDA #$01	; set parameter byte 1
 	STA SD_PB1
 	LDA #$AA	; set parameter byte 0
 	STA SD_PB0
	LDA #$87	; set crc
	STA SD_CRC
	LDA #CMD8	; send CMD8($000001AA) (get version)
	JSR SD_SEND_CMD	; response should be $01
	CMP #$01	; SD-Card present?
	BNE END_GET_VERS ; no, exit with result <> $01
			; yes, fall through to sd_wait_resp

; *****************************************************************************
; Wait for a 32 Bit Command R3 Response from SD-Card
; *****************************************************************************

SD_WAIT_RESP3	LDY #$00
READ_RESP3	STY YBUF
		JSR SD_WAIT_RESP ;yes, receive 4 response bytes
		LDY YBUF
		STA SD_PB3,Y	;store response bytes in PB0..3
		INY
		CPY #$04
		BNE READ_RESP3
END_GET_VERS	RTS

; *****************************************************************************
; Clear SD-Card Command Parameters
; *****************************************************************************

SD_CLEAR_CMD	LDA	#$00
		LDY	#$04			; 4 parameter bytes to clear
NEXT_PARAM	STA	SD_CMD,Y		; clear parameter byte
		DEY
		BNE	NEXT_PARAM		; more to clear?
		LDA	#$FF
		STA	SD_CRC			; no, finally set CRC byte to $FF
		RTS

; *****************************************************************************
; Send Command to SD-Card
; Input: A = Command Index
; *****************************************************************************

SD_SEND_CMD	STA	SD_CMD
		LDA PCR
		AND #%11011111		;CS = 0
		STA PCR
		JSR	SPI_BIN		; send one dummy
		LDX	#$00
SEND_BYTE	STX XBUF
		LDA	SD_CMD,X	; get one command byte
		JSR	SPI_OUT		; and send it
		LDX XBUF
		INX
		CPX	#$06		; all 6 cmd bytes send?
		BNE	SEND_BYTE	; no, send more bytes
					; yes, fall through to sd_wait_resp

; *****************************************************************************
; Wait for a 8 Bit Command R1 Response from SD-Card
; Output: A = Response Byte
; *****************************************************************************

SD_WAIT_RESP	LDX	#$08			; wait for max 8 cycles
READ_RESP1	JSR	SPI_BIN		; receive data
		CMP	#$FF			; is it a $FF?
		BNE	RESPONSE		; no, card did response
		DEX				; yes, try again
		BNE	READ_RESP1		; check for timeout
RESPONSE	TAX
		TXA				; set proper status flags for A
		RTS

; *****************************************************************************
; Wait for a Special Token Response from SD-Card
; Input:  A = Token Byte
; Output: A = Response Byte
; *****************************************************************************

SD_WAIT_TOKEN	STA	TEMP			; store token into TEMP variable
		LDY	#$FF			; load low byte of time out counter
		STY YBUF
		LDX	#$0A			; load high byte of time out counter
WAIT_RESP	JSR	SPI_BIN		; read byte from SPI
		DEC YBUF				; decrement wait counter
		BNE	WAIT_RESP0
		DEX
		BEQ	WAIT_RESP_END		; wait counter is 0 -> time out
WAIT_RESP0	CMP	TEMP			; did we read the token we are waiting for?
		BNE	WAIT_RESP		; no, read next byte
WAIT_RESP_END	RTS


SPI_INIT LDA PCR
	ORA #%11100000	;CS = 1
	STA PCR
	LDA #$40	;init VIA for SPI
	STA DRB
	LDA #%01000001	;MOSI = 1
	STA DDRB
	RTS


SPI_BIN	LDY #$40	;read byte from SPI, MOSI=1
	LDA #1		;set bit 0 as end marker
SPIBIN1	STY DRB		;CLK = 0
	INC DRB		;CLK = 1
	BPL SPIBIN2
	SEC		;input a %1
	ROL A
	BCC SPIBIN1	;C=0 until bit 0 arrives
	DEC DRB		;CLK = 0
	RTS

SPIBIN2	ASL A		;shift a 0 in A
	BCC SPIBIN1	;C=0 until bit 0 arrives
	DEC DRB		;CLK = 0
	RTS


SPI_OUT	LDX #0		;write A to SPI
	LDY #%01000000	;byte to write a %1
	SEC		;set marker bit
	ROL A		;Bit in C
SPIOUT1	BCS SPIOUT2
	STX DRB		;output a %0, CLK=0
SPIOUT3	INC DRB		;CLK = 1
	ASL A
	BNE SPIOUT1	;marker bit in C
	STY DRB		;CLK=0, MOSI=1
	RTS

SPIOUT2	STY DRB		;output a %1, CLK=0
	BNE SPIOUT3

; *****************************************************************************

SD_RESET JSR SD_CLEAR_CMD	;clear command parameters
	LDA #$95
	STA SD_CRC		; and set crc to $95 for CMD0
	JSR SPI_INIT		;CS=1; MOSI&CLK=1;MISO is input
	JSR SD_PREPARE		; send dummy sequence to SD-Card
	BNE RESET_SDC		; is MISO line high?
	LDA #CMD0		; no, send CMD0 (reset) to SD-Card
	JSR SD_SEND_CMD
	JSR SD_PREPARE		; send init dummy s=ence again
	BEQ END_SD_RESET	; MISO still low? Exit with A = $FF
RESET_SDC LDA #CMD0		; send CMD0 (reset) to SD-Card
	JMP SD_SEND_CMD		; response should be $01

END_SD_RESET
	LDA #$FF		; reset failed
	RTS


; **** Prepare SD-Card for Communication **************************************
;
; *****************************************************************************

SD_PREPARE	LDX	#10		; first send 80 clocks to SD-Card
SEND_CLOCK	JSR	SPI_BIN		; send 8 clock cycles
		DEX
		BNE	SEND_CLOCK	; send more clock cycles
		TAX
		TXA			; set proper status flags
SD_END		RTS


; *****************************************************************************
; Initialize Block Buffer Pointer
; *****************************************************************************

INIT_BLKBUF	LDA	#BLKB/256
		STA	BLKBUF+1
		LDA	#BLKB
		STA	BLKBUF
		RTS


DMABUF
BLKB = DMABUF+256


	END

