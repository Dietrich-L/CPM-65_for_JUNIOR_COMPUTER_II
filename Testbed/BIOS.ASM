;CPM-65 BIOS for JC II
;Testversion JC $D800
;D. LAUSBERG	(C) 1987

;V0.1	06.07.23	JC II version, erster Anlauf
;V0.2	26.07.23	error corrections - SETLBA, SD_ERROR

VERSION	= $02		;VERSION NUMBER

;FORMAT	SD	1024 KBYTES/DISK

;=====================================

;PAGE 00 CELLS

DMAV	= $FE		;DMA-VECTOR
DIRBFV	= $FC		;DIRBF-VECTOR
BIOSP	= $FA		;BIOS-POINTER
BLKB	= $FA		;BIOS Block Pointer
DPHV	= $F8		;DPH-VECTOR
JPBDOS	= $F0
MODE	= $EE		;SD Mode byte 0 byte mode; <>0 block mode

PLBA	= $E4	;LBA Pointer

XBUF	= $DF
YBUF	= $DE
TEMP	= $DD   ;temp storage

;SYSTEM CONSTANTS

BLKBUF	=  $600		;default buffer

CCP	= $CC00
BEGIN	= $D800

;CGET = $E04D		;CGET
CONST	= $F806
;ROM_CONIN = $E047	;CIN
;ROM_CONOUT = $E044	;BOUT
ROM_CONIN = $F809
ROM_CONOUT = $F80C
;SD_RD_LBLK_BUF = $F45F	;load sector in LBA to BLKBUF
;SD_WR_LBLK_BUF = $F492	;save sector in BLKBUF to LBA

;ROM_MONITOR = $E000	;Monitor cold start
ROM_MONITOR = $F830

;--- VIA 6522 adresses
;SPI driver  Mode 0 uses VIA DRB
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

;CONTROL CODES

BREAKC	= $03		;BREAK CODE
CLS	= $0C		;CLEAR SCREEN

;ERROR CODES

INVDRV	= $F9		;invalid drive
WRT_PROT = $86
SD_CHNG	= $87
NO_SD	= $88

;CONSTANTS

MAXTRK	= 128

SPT	= 32		;SECTORS PER TRACK
SPTDIV	= 5		;log(2) SPT
SPB	= 8		;SECTORS PER BLOCK
SPBDIV	= 3		;LOG(2) SPB
SYS	= 32		;SYSTEM sectors
BPD	= MAXTRK*SPT-SYS/SPB-1	;BLOCKS PER DISK
DIRSCS	= 32		;DIRECTORY SECTORS
DIRMSK	= %11110000	;DIR MASK FOR BAT
RPEXT	= 8*SPB*2 	;RECORD PER EXTENT
BATSIZ	= BPD/8		;SIZE OF BAT (64 bytes)

;==========================================

	ORG BEGIN

FBIOS	JMP BOOT		; 00
	JMP WBOOT		; 01
	JMP CONST		; 02
	JMP ROM_CONIN		; 03
	JMP ROM_CONOUT		; 04
	JMP LIST		; 05
	JMP AUXOUT		; 06
	JMP AUXIN		; 07
	JMP HOME		; 08
	JMP SELDSK		; 09
	JMP SETTRK		; 0A
	JMP SETSEC		; 0B
	JMP READ		; 0C
	JMP WRITE		; 0D
	JMP LISTST		; 0E
	JMP GET_VERSION		; 0F
	JMP ROM_MONITOR		; 10
	JMP MOUNT		; 11

;========== DATA AREA =============
;--- Disk Image TABLE ---

IMGTAB	DS 4*4,0		;Base Sector address of disk images mounted
IMGSTAT	DS 4,0		;Flag $FF valid image, $00 no image
SD_TYPE	DB 0		;SD Card Type

;Disk parameter block

DPHA	DW DIRBF	;DISK PARAMETER HEADER
	DW DMA		;FOR DRIVE A to D
	DW BAT

	DB SPB-1	;DISK PARAMETER BLOCK FOR DISK A-D
	DB SPBDIV
	DW BPD
	DB DIRSCS
	DB DIRMSK
	DB RPEXT
	DB SYS,0,0
	DB BATSIZ


BAT	DB %11110000	;Block Allocation Table Drive A-D
	DS BATSIZ	;max. 1 page

DRIVE	DB 0		;active drive

SECS	DS 4,0		;CPM-65 sector #, Byte 4 is not used

;--- buffer for SD CARD

LBA	DS 4,0		;LSB ... MSB
LBA_B	DS 4,$FF
LBA_F	DB 0		;LBA FLAG BIT7 = dirty

SD_CMD	DB 0	;CMD Byte
SD_PB3  DB 0	;Parameter Byte 3
SD_PB2	DB 0	;Parameter Byte 2
SD_PB1  DB 0 	;Parameter Byte 1
SD_PB0	DB 0	;Parameter Byte 0
SD_CRC	DB 0	;CRC Byte

;==================================

BOOT	LDA #$4C		;SET JMP BDOS
	STA JPBDOS
	LDA #CCP
	STA JPBDOS+1
	LDA #CCP/256
	STA JPBDOS+2
	JSR SD_INIT		;init card & set SD_MODE
	BCC B_ERR
	LDA #0			;a: only
	STA DRIVE		;SELECT BOOT DRIVE
	LDX #$0E		;VIA BDOS
	JSR JPBDOS
	LDX #0 			;WARM BOOT
	JMP JPBDOS

B_ERR	JMP ROM_MONITOR

WBOOT	LDA DRIVE		;SELECT DEFAULT DRIVE
	JSR SELDSK
	RTS


;CONST	JSR CGET
;	LDA #BREAKC
;	BCS CONST1
;	LDA #0
;CONST1	CLC
;	RTS


;---	CONIN	JMP ROM_CONIN


;---	CONOUT	JMP ROM_CONOUT


LIST	RTS


AUXOUT	RTS

AUXIN	RTS


HOME	;JSR SD_INIT
;	BCC HOMEX
;	CLC
;	RTS

;HOMEX	SEC
	RTS


SELDSK	CMP #4			;TEST FOR DRIVE A to D
	BCS SELDS2		;Invalid drive
	STA DRIVE		;SELECT DISK LOGICAL
	LDA #DPHA		;SET DPHVEC
	STA DPHV
	LDA #DPHA/256
	STA DPHV+1
	CLC
	RTS

SELDS2	LDA #INVDRV
	RTS


SETSEC	TAX			;sector pointer for p.00 in Accu
	LDA 0,X
	STA SECS
	LDA 1,X
	STA SECS+1
	LDA 2,X
	STA SECS+2
	RTS


SETTRK	LDA #$FB		;Sector not found
	SEC
	RTS


READ	JSR SETLBA		;SET LBA = IMGTAB + SECS/2
	JSR CHKBLK		;CHECK IF BLOCK VALID
	BCC SD_RD1
	JSR S_READ
	BCS SD_RD4
SD_RD1	LDA SECS
	LSR A
	LDY #0
	BCS SD_RD3
SD_RD2	LDA BLKBUF,Y
	STA (DMAV),Y
	INY
	BNE SD_RD2
	CLC
	RTS

SD_RD3	LDA BLKBUF+256,Y
	STA (DMAV),Y
	INY
	BNE SD_RD3
	CLC
	RTS

SD_RD4	JSR SD_INIT		;on error retry
	BCS READ
	LDA #NO_SD
	SEC
	RTS


WRITE	JSR SETLBA		;WRITE SD card
	JSR CHKBLK
	BCC SD_WR1
	JSR S_READ		;write implicitely
	BCS SD_WRE		;when SD buffer dirty
SD_WR1	LDA SECS
	LSR A
	LDY #0
	BCS SD_WR2
SD_WR3	LDA (DMAV),Y
	STA BLKBUF,Y
	INY
	BNE SD_WR3
	BEQ SD_WR4

SD_WR2	LDA (DMAV),Y
	STA BLKBUF+256,Y
	INY
	BNE SD_WR2	
SD_WR4	LDA #$80
	STA LBA_F		;BLKBUF dirty
	LDA SECS+2		;is it a dir sector?
	BNE SD_WR5
	LDA SECS+1
	BNE SD_WR5
	LDA SECS
	CMP #SYS+DIRSCS		
	BCS SD_WR5
	JSR SD_WB		;then write SD block immediate
	RTS

SD_WR5	CLC
	RTS

SD_WRE	JSR SD_INIT		;on error 1 retry
	BCS WRITE
	LDA #NO_SD
	SEC
	RTS


LISTST	RTS



GET_VERSION			;GET VERSION NUMBER

	LDA #VERSION
	RTS


MOUNT	TAX			;mount disk image on SD
	LDA 0,X			;load drive to be mounted
	CMP #4			;max A: - D:
	BCS MOU_ERR
	TAY
	LDA #$FF		;set drive byte as valid
	STA IMGSTAT,Y
	TYA
	ASL A			;*4
	ASL A
	TAY
MOUNT1	INX
	LDA 0,X
	STA IMGTAB,Y		;copy LBA block 0
	INY
	CPX #4			;4 bytes LBA
	BCC MOUNT1
	CLC
	RTS

MOU_ERR	LDA #INVDRV		;invalid drive #
	SEC
	RTS

;====== SUBROUTINES =======

SETLBA	LDX DRIVE
	LDA IMGSTAT,X	;Check for valid image base adr
	BEQ SETLBX
	TXA		;Drive*4 = pnt for base LBA
	ASL A
	ASL A
	PHA		;save X
	TAX		;start with LSB+2
	INX
	INX
	LDY #2
	CLC
SETLBA0	LDA SECS,Y	;SECS/2
	ROR A
	STA LBA,X
	DEX
	DEY
	BPL SETLBA0
	INY		;Y=0
	LDA #4
	STA TEMP	;counter for addition
	PLA
	TAX		;restore IMGTAB pointer
	CLC
SETLBA1	LDA LBA,Y	;LBA = IMGTAB + SECS/2
	ADC IMGTAB,X
	STA LBA,Y
	INX
	INY
	DEC TEMP
	BNE SETLBA1
	CLC
	RTS

SETLBX	LDA #INVDRV
	CLC
	RTS


CHKBLK	LDY #3		;CHECK IF BLK IN BUFFER VALID
CHKBLK2	LDA LBA,Y	;C=1 invalid
	CMP LBA_B,Y
	BNE CHKBL1
	DEY
	BPL CHKBLK2
	LDA LBA_F
	ASL A
	RTS

CHKBL1	SEC
	RTS


S_READ	BIT LBA_F		;SD_ READ
	BPL S_READ1		;if buffer dirty
	JSR S_SAVE		;SAVE SD_BUFFER
	BCS S_READX
S_READ1	LDX #LBA		;load LBA to BLKB
	LDY #LBA/256
	JSR SD_RD_LBLK_BUF
	BCS S_READX
	SEC
	RTS

S_READX	JSR SD_UPD		;UPDATE BLK/FLAG INFO
	CLC
	RTS


S_SAVE	LDX #LBA_B		;save old buffer to SD
	LDY #LBA_B/256
	JSR SD_WR_LBLK_BUF
	BCC S_SAVEX
	CLC
	RTS

S_SAVEX	SEC
	RTS


SD_WB	LDX #LBA		;Write SD_ block pysically
	LDY #LBA/256
	JSR SD_WR_LBLK_BUF
	BCS S_READX
	SEC
	RTS


SD_UPD	LDA LBA+3		;save LBA AND update LBA_FLAG
	STA LBA_B+3
	LDA LBA+2
	STA LBA_B+2
	LDA LBA+1
	STA LBA_B+1
	LDA LBA
	STA LBA_B
	LDA #0
	STA LBA_F
	RTS

; *****************************************************************************
; Read Single Data Block from Logical Address to Std. Block Buffer
; Input:  X,Y = Ptr[LO:HI] to 32 Bit LBA Address
; Output: C = 0 Error, C = 1 Data OK
;	  A = Error Code
; *****************************************************************************

SD_RD_LBLK_BUF	JSR INIT_BLKBUF		; set pointer to block buffer
					; fall through to sd_rd_lblk

; *****************************************************************************
; Read Single Data Block from Logical Address
; Input:  X,Y = Ptr[LO:HI] to 32 Bit LBA Address
;	  BLKBUF,BLKBUFH = 16 Bit Destination Address
; Output: C = 0 Error, C = 1 Data OK
;	  A = Error Code
; *****************************************************************************

SD_RD_LBLK	JSR LOAD_LBA		; convert LBA CMD ADR
					; fall through to sd_rd_blk

; *****************************************************************************
; Read Single Data Block
; Input:  SD_PB3..SD_PB0 = 32 Bit Command Block Address
;         BLKBUF,BLKBUFH = 16 Bit Destination Address
; Output: C = 0 Error, C = 1 Read OK
;	  A = Error Code
; *****************************************************************************

SD_RD_BLK	LDA	#CMD17		; send CMD17 (blk read)
		JSR	SD_SEND_BLK_CMD
		LDA	#DATA_TOKEN
		JSR	SD_WAIT_TOKEN	; wait for data token $FE
		CMP	#$FE		; is card ready for block read?
		CLC
		BNE	SD_RD_END	; did not receive data token, exit with C = 0
		LDX	#$01		; initialize page counter
		LDY	#$00		; initialize byte counter
SD_RD_BLK0	STY YBUF
		JSR	SPI_BIN		; read a byte
		LDY YBUF
		STA	(BLKB),Y	; and store it into the block buffer
		INY			; increment destination pointer
		BNE	SD_RD_BLK0	; pointer overflow? No, read next byte
		INC	BLKB+1		; yes, increment block buffer page
		DEX
		BPL	SD_RD_BLK0	; two pages read? no, read next byte
		INX
SD_RD_BLK1	JSR	SPI_BIN		; yes, read 3 more bytes (CRC H, CRC L, dummy)
		INX
		CPX	#$03		; all 3 bytes read?
		BNE	SD_RD_BLK1	; no, read next byte
		SEC			; yes, all data read, set C = 1
SD_RD_END	RTS

; *****************************************************************************
; Write Single Data Block from Std. Block Buffer
; Input:  SD_PB3..SD_PB0 = 32 Bit Command Block Address
; Output: C = 0 Error, C = 1 Read OK
;	  A = Error Code
; *****************************************************************************

SD_WR_BLK_BUF	JSR	INIT_BLKBUF	; set pointer to block buffer
		BEQ	SD_WR_BLK

; *****************************************************************************
; Write Single Data Block from Std. Block Buffer to Logical Address
; Input:  X,Y = Ptr[LO:HI] to 32 Bit LBA Address
; Output: C = 0 Error, C = 1 Data OK
;	  A = Error Code
; *****************************************************************************

SD_WR_LBLK_BUF	JSR	INIT_BLKBUF	; set pointer to block buffer
					; fall through to sd_rd_lblk

; *****************************************************************************
; Write Single Data Block to Logical Address
; Input:  X,Y = Ptr[LO:HI] to 32 Bit LBA Address
;	  BLKBUF,BLKBUFH = 16 Bit Source Address
; Output: C = 0 Error, C = 1 Data OK
;	  A = Error Code
; *****************************************************************************

SD_WR_LBLK	JSR	LOAD_LBA		; convert LBA CMD ADR
						; fall through to wr_rd_blk

; *****************************************************************************
; Write Single Data Block
; Input:  SD_PB3..SD_PB0 = 32 Bit CommandBlock Address
; Output: C = 0 Error, C = 1 Read OK
;	  A = Error Code
; *****************************************************************************

SD_WR_BLK	LDA	#CMD24			; send CMD24 (blk write)
		JSR	SD_SEND_BLK_CMD
		CMP	#$FE			; is card ready for block write?
		CLC
		BNE SD_WR_END
		JSR	SPI_OUT		; write data token
		LDX	#$01			; initialize page counter
		STX XBUF
		LDY	#$00			; initialize byte counter
SD_WR_BLK0	LDA	(BLKB),Y		; read next byte from buffer
		STY YBUF
		JSR	SPI_OUT		; and write it to the card
		LDY YBUF
		INY				; increment source pointer
		BNE	SD_WR_BLK0		; pointer overflow? No, write next byte
		INC	BLKB+1			; yes, increment block buffer page
		DEC XBUF
		BPL	SD_WR_BLK0		; two pages written? no, write next byte
		JSR	SPI_BIN		; yes, send a (dummy) CRC ($FFFF)
		JSR	SPI_BIN	
		JSR	SPI_BIN			; read response byte
		PHA
SD_WR_BUSY	JSR	SPI_BIN			; read next byte
		TAX
		BEQ	SD_WR_BUSY		; check if busy ($00)
		PLA
		AND	#$1F			; mask result bits
		CMP	#$05			; data accepted?
		CLC
		BNE	SD_WR_END		; no, exit with C = 0
		SEC				; yes, exit with C = 1
SD_WR_END	RTS

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

SD_DISK_RW	LDA	#WRT_PROT
		CLC
		RTS

SD_DISK_CHNG	LDA	#SD_CHNG
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
	LDA #NO_SD
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


; ********************************************
; Initialize Block Buffer Pointer
; ********************************************

INIT_BLKBUF	LDA	#BLKBUF/256
		STA	BLKB+1
		LDA	#BLKBUF
		STA	BLKB
		RTS

;--- Junior SPI routines --------------------

SPI_INIT LDA PCR
	ORA #%11100000	;CS = 1
	STA PCR
	LDA #$40	;init VIA for SPI
	STA DRB
	LDA #%01000001	;MOSI = 1
	STA DDRB
	RTS


SPI_BIN	LDY #$40	;read byte from SPI
	LDA #1		;set bit 0 as end marker
SPIBIN1	STY DRB		;CLK = 0, MOSI=1
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

; ********************************************

	
DMA	

DIRBF	=  DMA+256


	END
