;BOOT.COM -- CP/M-65 SD BOOT UTILITY JC II Testbed Version
;BY D. LAUSBERG	 (C)1988
;V1.0	21.07.23
;V1.1	26.07.23	$CC00 version
;V1.2	27.07.23	code improvements
;V1.3	03.08.23	saves SD_TYPE in BIOS DPH+17
;V1.4	15.08.23	boot image select
;V1.5	08.01.24	FAT32&FAT16
;V1.6	22.01.24	Fast SPI version

VERSION	= $16

;SYSTEM CONSTANTS
DMA	= $FE
DPH	= $F8
FCB1	= $F6
FCB2	= $F4
BDOS	= $F0
MODE	= $1A		;SD Mode byte 0 byte mode; <>0 block mode
INBUF	= $EC
CCPV	= $DE

TPA	= $200
CCP	= $CC00
BIOS	= $D800
ROM_MONITOR = $E000	;Monitor cold start

GETCHR	= $F809
PRTCHR	= $F80C


;Zero Page adresses
MCNT	= $00		;counter
LBA	= $01		;LSB ... MSB base LBA for SD read

BASE	= $05		;LBA of 1. dir sector/1. data sector - 2 cluster
NFAT	= $09
SEC_CLUS = $0A
NDIR	= $0B

N32	= $28		;32 bit argument
DIR_NP	= $2C		;pointer to nr of dir entry
DIR_FNP	= $2E		;dir filename pointer
IMAGE	= $30		;image to be mounted - Drive, LBA
CNT_I	= $35		;# images found
CNT_Y	= $36		;counter

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
BLKB	= $92

;--- VIA 6522 adresses
;SPI driver  Mode 0 uses VIA DRB
;BIT 1	CS
;Bit 0	MOSI
; CB 1	CLK
; CB 2	MISO

DRB	= $F400
DDRB	= $F402
T2CL	= $F408
T2CH	= $F409
SR	= $F40A
ACR	= $F40B
IFR	= $F40D
IER	= $F40E

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

MAX_IMG	= $10		;max # of bootable images on SD

;BDOS COMMANDS

CBOOT	= $00
CBIOS	= $1A

;BIOS COMMANDS

_SELDSK	= $09
_MOUNT	= $11

;CONTROL CODES

EOT	= $00
BS	= $08
LF	= $0A
CLS	= $0C
CR	= $0D
SPACE	= $20
SEMI	= $3B

;ERROR CODES

EOF	= $1A

INVDRV	= $85
WRT_PROT = $86
SD_CHNG	= $87
NO_SD	= $88


	ORG TPA

BOOT	LDY #BOOTM-BOOTM
	JSR PRTSTR
	JSR SPI_INIT		;initialize SPI
	JSR SD_INIT		;initialize SD card
	BCC B_ERR
	JSR SEL_BOOT_DISK	;select boot disk
	BCS B_ERR
	JSR INCLBA		;CCP starts in block 1
BOOT2	LDA #CCP		;and boot it
	STA BLKB
	LDA #CCP/256
	STA BLKB+1
BOOT1	JSR R_LBA		;read sector in LBA to BLKBUF
	BCS B_ERR
	JSR INCLBA		;LBA=LBA+1
	LDA BLKB+1
	CMP #ROM_MONITOR/256	;all sector read?
	BCC BOOT1
BOOT6	LDA #IMAGE
	JSR _MOUNT*3+BIOS	;BIOS MOUNT command
	LDA #0			;select A:
	JSR _SELDSK*3+BIOS	;BIOS SELDSK command
	LDY #17
	LDA SD_TYPE
	STA (DPH),Y		;save SD_TYPE to BIOS
	SEI
	JMP BIOS		;COLD BOOT


B_ERR	LDY #ERRM-BOOTM
	JSR PRTSTR		;print error message

BOOT_X	LDX #CBOOT		;and fall back to CPM-65
	JMP BDOS

;---  CP/M-65 BOOT data area  -------------------

SD_TYPE	DB 0			;SD Card Type

IMG_SIZ	DB 0,0,$10,0	;image size 1 MB
MINUS_2	DB $FE,$FF,$FF,$FF	;-2

;---  MESSAGES  -----------------------------

BOOTM	DB CR,LF,'CP/M-65 for JC-II Boot Loader V'
	DB VERSION/16+$30,'.',VERSION*$1000/$1000+$30,CR,LF,EOT
ERRM	DB CR,LF,'BOOT failed',CR,LF,EOT
SELM	DB CR,LF,'select image: ',EOT

;--- Suboutines -----------------------------

INCLBA	LDX #0			;LBA = LBA+1
INCLBA1	INC LBA,X
	BNE INCLBAX
	INX
	CPX #4
	BCC INCLBA1
INCLBAX	RTS


PRTSTR	LDA BOOTM,Y		;print message
	BEQ PRTSTRX
	JSR PRTCHR
	INY
	BNE PRTSTR
PRTSTRX	RTS


SEL_BOOT_DISK
INFO	JSR SET_DIR_INFO	;set directory info parameters
	BCS INFOX
	JSR DISP_INFO		;display files in directory
	BCC MOUNT
INFOX	RTS

MOUNT	LDA #0			;mount image on A:
	STA IMAGE		;save drive
	LDA CNT_I
	BEQ MOUNT4
	LDY #SELM-BOOTM
	JSR PRTSTR
GCHR	JSR GETCHR		;GET image nr
	STA MCNT
	CMP #$03		;CTRL-C?
	BEQ MOUNTX
	CMP #'0			;convert to HEX
	BCC GCHR		;if not a valid HEX, try again
	CMP #$3A
	BCC GCHR2
	CMP #'A
	BCC GCHR
	CMP #'G
	BCS GCHR
	ADC #9
GCHR2	AND #$0F
	CMP CNT_I
	BCS GCHR		;valid input?
	PHA
	LDA MCNT
	JSR PRTCHR		;print # selected
	PLA
	ASL A			;image index * 4
	ASL A
	TAY
	LDX #0
MOUNT2	LDA IMG_LBA,Y		;set image data
	STA IMAGE+1,X
	STA LBA,X
	INY
	INX
	CPX #4
	BCC MOUNT2
	CLC
MOUNTX	RTS

MOUNT4	SEC			;no image
	RTS


SET_DIR_INFO			;set dir params
	LDA #0
	LDY #3			;reset LBA, BASE, N32
SDIR1	STA LBA,Y
	STA BASE,Y
	STA N32,Y
	DEY
	BPL SDIR1
	JSR R_LBA_B		;read sector 0 of SD
	BCS SDIRX
	LDA BLKBUF+$1BE+4		;OS-Type
	BEQ MOUNT4
	LDY #3
SDIR2	LDA BLKBUF+$1BE+8,Y
	STA BASE,Y		;BASE = begin of partition
	STA LBA,Y		;LBA = begin of partition
	DEY
	BPL SDIR2
	JSR R_LBA_B		;read sector 0 of partition 1
	BCS SDIRX
	LDA BLKBUF+$0D		;save # sectors/cluster
	STA SEC_CLUS
	LDA BLKBUF+$11		;save # dir entries
	STA NDIR
	LDA BLKBUF+$12
	STA NDIR+1
	LDA BLKBUF+$0E		;N32 = #reserved sectors
	STA N32
	LDA BLKBUF+$0F
	STA N32+1
	JSR ADD			;BASE = BASE + N32
	LDA BLKBUF+$10
	STA NFAT		;#FATs
	LDA BLKBUF+$16		;N32 = FAT size
	STA N32
	LDA BLKBUF+$17
	STA N32+1
	ORA N32			;N32 = 0? -> FAT32
	BEQ SDIR4
SDIR3	JSR ADD
	DEC NFAT
	BNE SDIR3
	JSR BASE2LBA		;BASE -> LBA
	JSR R_LBA_B		;read sector 0 of directory
SDIRX	RTS

SDIR4	LDA BLKBUF+$24		;N32 = FAT32 size
	STA N32
	LDA BLKBUF+$25
	STA N32+1
	LDA BLKBUF+$26
	STA N32+2
	LDA BLKBUF+$27
	STA N32+3
	JMP SDIR3


DISP_INFO			;display directory of SD
	JSR SET_PARAMS		;set DIR_NP, CNT_I, BASE
DISINF1	JSR DIS_FN		;display filename indexed by DIR_NP if valid image
	BCS DISINF2		;and store its LBA in FNAMES 
	JSR NXT_FN		;setup for next filename
	BCC DISINF1
	CMP #EOF
	BNE DISINFX
DISINF2	CLC
	RTS

DISINFX SEC
	RTS


DIS_FN	LDA #BLKBUF		;DIR_FNP = DMA + PNT
	STA DIR_FNP
	LDA #BLKBUF/256
	STA DIR_FNP+1
	LDA DIR_NP		;PNT = DIR_NP*32 mod 256
	ASL A
	ASL A
	ASL A
	ASL A
	ASL A
	BCC DISFN2
	INC DIR_FNP+1		;2. page
	CLC
DISFN2	ADC DIR_FNP
	STA DIR_FNP
	BCC DISFN1
	INC DIR_FNP+1
DISFN1	LDY #0
	LDA (DIR_FNP),Y		;check special byte
	CMP #$E5		;deleted?
	BEQ DISFNX
	LDY #$0B		;check attribute
	LDA (DIR_FNP),Y
	AND #%11011111		;mask archive bit
	BNE DISFNX
	JSR CHK_FS		;check filesize
	BCS DISFNX
	LDA #CR
	JSR PRTCHR
	LDA #LF
	JSR PRTCHR
	LDA CNT_I
	JSR PRTNIB		;print nr
	LDA #':
	JSR PRTCHR
	JSR PRT_FN
	JSR STO_LBA		;store LBA of 1. sector of the image
	INC CNT_I
	LDA CNT_I
	CMP #MAX_IMG
	RTS

DISFNX	CLC
	RTS


STO_LBA	LDY #$1A		;N32 = 1. cluster of image (LSB, LSB+1)
	LDA (DIR_FNP),Y
	STA N32
	INY	
	LDA (DIR_FNP),Y
	STA N32+1
	LDY #$14		;N32 = 1. cluster of image (LSB+2, LSB+3)
	LDA (DIR_FNP),Y
	STA N32+2
	INY	
	LDA (DIR_FNP),Y
	STA N32+3
	JSR MUL_SPC		;N32 = N32 * SEC_CLUS
	LDA CNT_I		;store LBA of 1. sector of the image
	ASL A
	ASL A
	TAY
	LDX #0
	LDA #4
	STA MCNT
	CLC
STOLBA1	LDA BASE,X
	ADC N32,X
	STA IMG_LBA,Y
	INY
	INX
	DEC MCNT
	BNE STOLBA1
	RTS


NXT_FN	INC DIR_NP		;setup for next filename
	BNE NXT_FN1		;DIR_NP = DIR_NP + 1
	INC DIR_NP+1
NXT_FN1	LDA DIR_NP+1
	CMP NDIR+1
	BNE NXT_FN4
	LDA DIR_NP
	CMP NDIR
	BCS NXT_FN3
NXT_FN4	LDA DIR_NP		;check for next sector
	AND #%00001111
	BNE NXT_FN2
	JSR INCLBA		;INC LBA
	JSR R_LBA_B		;read sector in LBA to BLKBUF
	RTS

NXT_FN2	CLC
	RTS

NXT_FN3	LDA #EOF		;end of directory
NXT_FNX	RTS


SET_PARAMS			;set DIR_NP, CNT_I, BASE
	LDA #0			;DIR_NP=0
	STA DIR_NP
	STA DIR_NP+1
	STA N32+1
	STA CNT_I		;CNT_I = 0
	LDA NDIR+1		;BASE = BASE + NDIR*32/512
	STA N32			;N32 = NDIR/256
	LDY #4			;N32 = N32*16
SET_P1	JSR MUL2
	DEY
	BNE SET_P1
	JSR ADD
	LDY #3			;BASE = BASE - 2*SEC_CLUS
SET_P2	LDA MINUS_2,Y
	STA N32,Y
	DEY
	BPL SET_P2
	JSR MUL_SPC		;N32 * SEC_CLUS
	JSR ADD
	LDA #128		;max. 128 DIR entries
	STA NDIR
	LDA #0
	STA NDIR+1
	RTS


MUL_SPC	LDY SEC_CLUS		;N32 * SEC_CLUS
MULSPC1	TYA
	LSR A
	TAY
	BCS MULSPCX
	JSR MUL2
	JMP MULSPC1

MULSPCX	RTS
	

MUL2	ASL N32			;N32*2
	ROL N32+1
	ROL N32+2
	ROL N32+3
	RTS


ADD	CLC			;BASE = BASE + N32
	LDX #0
	LDY #3
ADD1	LDA BASE,X
	ADC N32,X
	STA BASE,X
	INX
	DEY
	BPL ADD1
	RTS


BASE2LBA		;copy BASE to LBA
	LDX #3
B2LBA	LDA BASE,X
	STA LBA,X
	DEX
	BPL B2LBA
	RTS


CHK_FS	LDY #$1F		;check for valid image file size
	LDX #3
CHK_FS1	LDA (DIR_FNP),Y
	CMP IMG_SIZ,X
	BNE CHK_FSX
	DEY
	DEX
	BPL CHK_FS1
	CLC
	RTS

CHK_FSX	SEC
	RTS

PRT_FN	LDY #0			;print filename
PRT_FN1	LDA (DIR_FNP),Y
	JSR PRTCHR
	INY
	CPY #12
	BCS PRT_FNX
	CPY #8
	BNE PRT_FN1
	LDA #'.
	JSR PRTCHR
	JMP PRT_FN1

PRT_FNX	RTS


PRTHEX	PHA			;PRINTS A HEX NUMBER
	LSR A
	LSR A
	LSR A
	LSR A
	JSR PRTNIB		;PRINT NIBBLE
	PLA
	AND #$0F

PRTNIB	CMP #$0A
	BCC PRTNI1
	ADC #6
PRTNI1	ADC #$30
	JSR PRTCHR
	RTS

;---------------------------------------------

R_LBA_B	JSR INIT_BLKBUF		;BLKB = BLKBUF

R_LBA	LDX #LBA		;read sector in LBA to BLKBUF
	LDY #LBA/256
	JSR SD_RD_LBLK		;read 512 bytes from SD
	BCC R_LBA1
	CLC
	RTS

R_LBA1	SEC
	RTS

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
;	  BLKB,BLKBH = 16 Bit Destination Address
; Output: C = 0 Error, C = 1 Data OK
;	  A = Error Code
; *****************************************************************************

SD_RD_LBLK	JSR	LOAD_LBA		; convert LBA CMD ADR
						; fall through to sd_rd_blk
; *****************************************************************************
; Read Single Data Block
; Input:  SD_PB3..SD_PB0 = 32 Bit Command Block Address
;         BLKB = 16 Bit Destination Address
; Output: C = 0 Error, C = 1 Read OK
;	  A = Error Code
; *****************************************************************************

SD_RD_BLK LDA #CMD17	; send CMD17 (blk read)
	JSR	SD_SEND_CMD
	BNE	SD_RESP_ERR	; response <> 0 check error type
	LDA	#DATA_TOKEN	
	LDX #0
	STX T2CL	;set timer to 4 us/bit
	LDA #DATA_TOKEN
	JSR SD_WAIT_TOKEN	; wait for data token $FE
	CMP #$FE	; is card ready for block read?
	CLC
	BNE SD_RD_END	; did not receive data token, exit with C = 0
	LDX #$01	; initialize page counter
	LDY #$00	; initialize byte counter
SD_RD_BLK0 JSR	SPI_BIN	; read a byte
	STA (BLKB),Y	; and store it into the block buffer
	INY		; increment destination pointer
	BNE SD_RD_BLK0	; pointer overflow? No, read next byte
	INC BLKB+1	; yes, increment block buffer page
	DEX
	BPL SD_RD_BLK0	; two pages read? no, read next byte
SD_RD_BLK1 JSR SPI_BIN	; yes, read 3 more bytes (CRC H, CRC L, dummy)
	INX
	CPX #$02	; all 3 bytes read?
	BNE SD_RD_BLK1	; no, read next byte
	LDX #5		;set timer to 14 us/bit
	STX T2CL
	SEC		; yes, all data read, set C = 1
SD_RD_END RTS

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
READ_RESP3	JSR SD_WAIT_RESP ;yes, receive 4 response bytes
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
		LDA #$01
		STA DRB			;CS = 0, MOSI = 1
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

SD_WAIT_RESP	LDX	#$08		; wait for max 8 cycles
READ_RESP1	JSR	SPI_BIN		; receive data
		CMP	#$FF		; is it a $FF?
		BNE	RESPONSE	; no, card did respond
		DEX			; yes, try again
		BNE	READ_RESP1	; check for timeout
RESPONSE	TAX
		TXA			; set proper status flags for A
		RTS

; *****************************************************************************
; Wait for a Special Token Response from SD-Card
; Input:  A = Token Byte
; Output: A = Response Byte
; *****************************************************************************

SD_WAIT_TOKEN	STA	TEMP			; store token into TEMP variable
		LDY	#$FF			; load low byte of time out counter
		LDX	#$0A			; load high byte of time out counter
WAIT_RESP	JSR	SPI_BIN		; read byte from SPI
		DEY				; decrement wait counter
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
	JSR SPI_INIT		; CS=1; MOSI&CLK=1;MISO is input
	JSR SD_PREPARE		; send dummy sequence to SD-Card
	BNE RESET_SDC		; is MISO line high?
	LDA #CMD0		; no, send CMD0 (reset) to SD-Card
	JSR SD_SEND_CMD
	JSR SD_PREPARE		; send init dummy sequence again
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

INIT_BLKBUF	LDA	#BLKBUF/256
		STA	BLKB+1
		LDA	#BLKBUF
		STA	BLKB
		RTS


;--- Junior SPI routines --------------------

SPI_INIT LDX #%00000011	;init VIA for SPI
	STX DRB		;CS = 1, MOSI = 1
	STX DDRB	;Bit 0  MOSI; Bit 1  CS
	INX		;SR mode 010 = $04
	STX ACR
	LDA #0
	STA T2CH
	INX		;Timer2 = 14 us = $05
	STX T2CL
	STA SR
	LDX #24		;wait 100(500) ms for (very) slow SD cards
SPI_IN1	JSR SPI_IN2	;delay 4.3 ms
	SBC #1
	BCS SPI_IN1
	DEX
	BNE SPI_IN1
SPI_IN2	RTS


SPI_BIN	LDA IFR		;read byte from SPI
	AND #$04	;test SR bit
	BEQ SPI_BIN
	STA IFR		;clear SR bit
	LDA SR
	RTS


SPI_OUT	PHA		;write A to SPI
SPIOUT1	LDA IFR		;read byte from SPI
	AND #$04	;test SR bit
	BEQ SPIOUT1
	STA IFR		;clear SR bit
	LDX #0
	LDY #%00000001	;byte to write a %1
	PLA
	SEI
	SEC		;set marker bit
	ROL A		;Bit in C
	BCS SPIOUT7
	STX SR		;start T2
	STX DRB		;set bit 7 = 0
	ASL A		;shift bit 6 in C
	BNE SPIOUT3

SPIOUT7	STX SR		;start T2
	STY DRB		;set bit 7 = 1
	ASL A		;shift bit 6 in C
	BNE SPIOUT3

SPIOUT2	STX DRB		;output a %0
	ASL A
	BEQ SPIOUT4
SPIOUT3	BIT $00		;3 us delay
SPIOUT6	BCC SPIOUT2	;14 us per bit
	STY DRB		;output a %1
	ASL A
	BNE SPIOUT3	;marker bit in C
SPIOUT4	STY DRB		;CS = 0  MOSI = 1
	CLI
	RTS


DMABUF
BLKBUF = DMABUF+256
IMG_LBA	= BLKBUF+512		;Image LBAs

	END

