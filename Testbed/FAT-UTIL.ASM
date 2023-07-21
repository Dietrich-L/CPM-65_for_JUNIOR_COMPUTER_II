;FAT-UTIL.COM -- CP/M-65 SD UTILITY JC II Version
;BY D. LAUSBERG	 (C)1988
;V1.0	18.07.23

VERSION	= $10

;SYSTEM CONSTANTS
DMA	=  $FE
DPH	=  $F8
FCB1	=  $F6
FCB2	=  $F4
BDOS	=  $F0
INBUF	=  $EC
CCPV	=  $DE
TPA	=  $0200
BUFBEG	=  $8000

;Zero Page adresses

CMDVEC	= $00
CMDKEY	= $01
PNT	= $02
CNT	= $03
MCNT	= $04
RCOUNT	= $05
BUFFER	= $08
NUMBER	= $09
HEXL	= $0A
HEXH	= $0B
HEXX	= $0C
DIVL	= $0D
DIVM	= $0E
DIVH	= $0F
DRIVE	= $10
ERRNO	= $11
SEC	= $12

SYS	= $18


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

BOOT	= $00
CONIN	= $01
CONOUT	= $02
STROUT	= $09
GETLIN	= $0A

;CONTROL CODES

EOT	= $00
BS	= $08
LF	= $0A
CLS	= $0C
CR	= $0D
SPACE	= $20
SEMI	= $3B

;ERROR CODES

NOCOM	= $80
MISPAR	= $81
ILLPAR	= $82
TOOMCH	= $83
EOL	= $84
INVDRV	= $85
WRT_PROT = $86
SD_CHNG	= $87
NO_SD	= $88

	ORG TPA

DUTIL	JSR INIT 		;INIT VARIABLES

DUTILL	JSR STATUS
	LDA #PROMPT
	LDY #PROMPT/256
	JSR PRTSTR
	LDX #GETLIN
	JSR BDOS
	LDY #0			;SET COMMAND POINTER
	STY CMDVEC
DUTIL1	JSR DECODE		;DECODE AND EXEC COMMAND
	BCC DUTIL1
	CMP #EOL 		;END OF COMMAND
	BEQ DUTILL
	JSR ERROR
	JMP DUTILL


INIT	LDA #0			;RESET VARIABLES
	LDX #$40
INIT2	STA 0,X
	DEX
	BPL INIT2
	LDA #BUFBEG		;SET BUFFER VECTOR
	STA BUFFER
	LDA #BUFBEG/256
	STA BUFFER+1
	LDA #DMABUF		;set DMA
	STA DMA
	LDA #DMABUF/256
	STA DMA+1
	JSR SPI_INIT		;initialize SPI
	JSR SD_INIT		;initialize SD card
	BCC INIT1
	JSR DRVPAR		;GET DRIVE PARAM'S
	JSR READS		;read sector 0
	RTS

INIT1	JSR ERROR
	BCC INIT
	LDX #BOOT
	JMP BDOS


DRVPAR	LDA #0			;RESET VARIABLES
	STA SYS
	STA SYS+1
	STA SYS+2
	STA DRIVE		;always A:
	RTS


STATUS	LDA #STATM1		;DISPLAY STATUS
	LDY #STATM1/256
	JSR PRTSTR
	LDA DRIVE		;PRINT DRIVE
	CLC
	ADC #'A
	JSR PRTCHR
	LDA #STATM2
	LDY #STATM2/256
	JSR PRTSTR
	LDY #2
STATUS1	LDA SEC,Y
	JSR PRTHEX		;PRINT HEX VALUE
	DEY
	BPL STATUS1
	RTS


PRTDEC	JSR COMNUM		;PRINTS DECIMAL
	PHA
	TYA
	JSR COMNUM
	PHA
	TYA
	JSR PRTNUM
	PLA
	JSR PRTNUM
	PLA
	JSR PRTNUM
	RTS


COMNUM	LDY #0			;DIV/10
COMNU1	SEC
	SBC #10
	BCC COMNU2
	INY
	BNE COMNU1

COMNU2	ADC #10
	RTS


PRTNUM	ORA #$30 		;PRINT A NUMBER
	JMP PRTCHR


DECODE	JSR GNCHR		;GET NEXT CHR
	BCS DECODX
	CMP #SEMI		;IS IT A SEPARATOR
	BNE DECOD1
	JSR GNCHR
	BCS DECODX
DECOD1	LDY #0			;SEARCH COMMAND
	STA CMDKEY
DECOD4	LDA CMDTAB,Y
	BEQ DECOD2		;COMMAND NOT FOUND
	CMP CMDKEY
	BEQ DECOD3		;FOUND
	INY
	INY
	INY
	BNE DECOD4

DECOD3	INY
	LDA CMDTAB,Y
	PHA
	INY
	LDA CMDTAB,Y
	PHA
	RTS			;EXEC

DECOD2	LDA #NOCOM		;UNKNOWN COMMAND
	SEC
DECODX	RTS

CMDTAB	DB 'S'
	DD SECRD-1
	DB 'D'
	DD DUMP-1
	DB 'C'
	DD CHANGE-1
	DB '+'
	DD PLUS-1
	DB '-'
	DD MINUS-1
	DB 'R'
	DD READS-1
	DB 'W'
	DD WRITES-1
	DB 'X'
	DD EXIT-1
	DB '?'
	DD HELP-1
	DB 'Z'
	DD WAIT-1
	DB '>'
	DD STOBUF-1
	DB '<'
	DD STODMA-1
	DB '/'
	DD REPEAT-1
	DB 'B'
	DD SETBUF-1
	DB 'L'
	DD LOGON-1

	DB $00

;==========  COMMANDS  ============= 


SECRD	JSR GETSEC		;GET HEX BYTE
	BCS SECRDX
	JSR READS		;READ SECTOR
SECRDX	RTS


DUMP	JSR STATUS		;DUMP DMA
	LDA #0
DUMP3	STA PNT			;SET POINTER
	JSR CRLF
	LDY PNT
DUMP1	LDA (DMA),Y
	JSR DISHEX
	INY
	TYA
	AND #$0F
	PHA
	CMP #8
	BNE DUMP4
	LDA #BS
	JSR PRTCHR
DUMP4	PLA
	BNE DUMP1
	LDY PNT
DUMP2	LDA (DMA),Y
	JSR DISASC
	INY
	TYA
	AND #$0F
	BNE DUMP2
	TYA
	BNE DUMP3
	CLC
	RTS


CHANGE	JSR GNCHR		;GET NEXT CHR
	BCS CHANGX
	CMP #'H
	BEQ CHEX
	CMP #'A
	BEQ CASC
	LDA #ILLPAR		;ILLEGAL PARAMETER
CHANGX	SEC
	RTS

CHEX	JSR GETHEX		;GET DMA POINTER
	BCS CHANGX
	STA PNT
CHEX1	JSR GETHEX		;GET HEX VALUE
	BCS CHEX2
	LDY PNT
	STA (DMA),Y		;REPLACE
	INC PNT
	BNE CHEX1
	LDA #TOOMCH		;TOO MUCH PARAMETERS
	SEC
	RTS

CHEX2	CMP #MISPAR
	BNE CHANGX
	CLC
	RTS

CASC	JSR GETHEX		;GET DMA POINTER
	BCS CHANGX
	STA PNT
CASC1	JSR GNCHR		;GET HEX VALUE
	BCS CHANGX
	LDY PNT
	STA (DMA),Y		;REPLACE
	INC PNT
	BNE CASC1
	LDA #TOOMCH		;TOO MUCH PARAMETERS
	SEC
	RTS


PLUS	LDX #0
PLUS2	INC SEC,X
	BNE PLUS1
	INX
	CPX #3
	BCC PLUS2
PLUS1	; JSR CMSEC
	JSR READS
	RTS


MINUS	LDX #0
MINUS2	DEC SEC,X
	LDA SEC,X
	CMP #$FF
	BNE MINUS1
	INX
	CPX #3
	BCC MINUS2
;	JSR CMSEC
MINUS1	JSR READS
	RTS


READS	JSR SETSEC		;SET SECTOR
	JSR READ		;AND READ IT
	RTS


WRITES	JSR SETSEC		;SET SECTOR
	JSR WRITE		;AND READ IT
	RTS


EXIT	LDX #BOOT
	JSR BDOS


HELP	LDA #HELPM
	LDY #HELPM/256
	JSR PRTSTR
	RTS


WAIT	JSR GDEC 		;WAIT NN/10 S
	BCS WAITX
	STA CNT
WAIT3	LDA #10
	STA MCNT 		;100 MS
WAIT2	LDX #78
WAIT1	DEY
	BNE WAIT1
	DEX
	BNE WAIT1
	DEC MCNT
	BNE WAIT2
	DEC CNT
	BNE WAIT3
	CLC
WAITX	RTS


STOBUF	LDY #0			;SAVE DMA TO BUFFER
STOBU1	LDA (DMA),Y
	STA (BUFFER),Y
	INY
	BNE STOBU1
	CLC
	RTS


STODMA	LDY #0			;STORE BUFFER TO DMA
STODM1	LDA (BUFFER),Y
	STA (DMA),Y
	INY
	BNE STODM1
	CLC
	RTS


REPEAT	LDA RCOUNT		;REPEAT COMMAND
	BEQ REPEA1
REPEA3	DEC RCOUNT		;ONE MORE TIME
	BEQ REPEA5
	LDA #0
	STA CMDVEC
	CLC
	RTS

REPEA1	JSR GDEC 		;GET NO. OF REPEATS
	BCS REPEA2
	STA RCOUNT
	CMP #0
	BNE REPEA3
	LDA #ILLPAR
REPEA4	SEC
	RTS

REPEA2	CMP #MISPAR
	BNE REPEA4
	LDA #10			;DEFAULT 10 TIMES
	STA RCOUNT
	BNE REPEA3

REPEA5	LDA #EOL
	SEC
	RTS


SETBUF	JSR GETHEX		;GET BUFFER ADDRESS
	BCS SETBUX
	STY BUFFER+1
	STA BUFFER
SETBUX	RTS


LOGON	JSR SD_INIT		;init SD card
	BCC LOGON4
	CLC
	RTS

LOGON4	JSR ERROR
	BCC LOGON
	JSR INIT
	CLC
	RTS


;======  SUBROUTINES  ============== 

DISHEX	JSR PRTHEX		;DISPLAYS A HEX
	LDA #SPACE
	JSR PRTCHR
	RTS


DISASC	AND #$7F
	CMP #$20
	BCC DISAS1
	CMP #$7F
	BCC DISAS2
DISAS1	LDA #'.
DISAS2	JSR PRTCHR
	RTS


GDEC	JSR GETHEX		;GETS A DECIMAL FROM LINE
	BCS GDECX
	AND #$0F
	CMP #10
	BCS GDEC1
	STA NUMBER		;EINER
	LDA HEXL
	AND #$F0
	LSR A			;ZEHNER*8
	PHA
	CLC
	ADC NUMBER
	STA NUMBER
	PLA
	LSR A
	LSR A			;ZEHNER*2
	CLC
	ADC NUMBER
	CPY #3			;Y= HEXH
	BCS GDEC1
GDEC5	DEY
	BMI GDEC4
	ADC #100
	BCC GDEC5
GDEC1	LDA #ILLPAR
	SEC
GDECX	RTS

GDEC4	STA NUMBER
	CLC
	RTS


GETSEC	LDA #0			;GET sector nr
	STA HEXL
	STA HEXH
	STA HEXX
	TAX
GETSEC2	JSR GETNIB
	BCS GETSEC1
	INX
	CPX #6
	BCC GETSEC2
GETSEC5	LDA #ILLPAR		;ILLEGAL PARAMETER
	SEC
	RTS

GETSEC1	CPX #0
	BNE GETSEC3
	CMP #SPACE
	BEQ GETSEC2
	CMP #EOL
	BEQ GETSEC6
	CMP #SEMI
	BNE GETSEC5
GETSEC6	LDA #MISPAR
	SEC
	RTS

GETSEC3	CMP #SEMI
	BEQ GETSEC4
	CMP #',
	BEQ GETSEC4
	CMP #EOL
	BNE GETSEC5
GETSEC4	LDA HEXX
	STA SEC+2
	LDA HEXH
	STA SEC+1
	LDA HEXL
	STA SEC
	CLC
	RTS



GETHEX	LDA #0			;GET HEX NUMBER FROM LINE
	STA HEXL 		;RESET HEX
	STA HEXH
	TAX
GETHE2	JSR GETNIB		;GET NIBBLE TO HEX
	BCS GETHE1
	INX
	CPX #5
	BCC GETHE2
GETHE5	LDA #ILLPAR		;ILLEGAL PARAMETER
	SEC
	RTS

GETHE1	CPX #0
	BNE GETHE3
	CMP #SPACE
	BEQ GETHE2
	CMP #EOL
	BEQ GETHE6
	CMP #SEMI
	BNE GETHE5
GETHE6	LDA #MISPAR
	SEC
	RTS

GETHE3	CMP #SEMI
	BEQ GETHE4
	CMP #',
	BEQ GETHE4
	CMP #EOL
	BNE GETHE5
GETHE4	LDA HEXL
	LDY HEXH
	CLC
	RTS


GETNIB	JSR GNCHR		;GET NIBBLE TO HEX
	BCS GETNIX
	CMP #'0
	BCC GETNI1
	CMP #$3A
	BCC GETNI2
	CMP #'A
	BCC GETNI1
	CMP #'G
	BCC GETNI3
GETNI1	SEC
GETNIX	RTS

GETNI3	CLC
	ADC #9
GETNI2	AND #$0F
	LDY #4
GETNI4	ASL HEXL
	ROL HEXH
	ROL HEXX
	DEY
	BNE GETNI4
	ORA HEXL
	STA HEXL
	CLC
	RTS


GNCHR	LDY #0
	INC CMDVEC
	LDA CMDVEC
	CMP (INBUF),Y
	BCS GNCHRX
	TAY
	LDA (INBUF),Y
	JSR UPCASE
	CLC
	RTS

GNCHRX	LDA #EOL
	RTS


UPCASE	CMP #'a			;LOWER --> UPPER CASE
	BCC UPCASX
	CMP #'~
	BCS UPCASX
	AND #$5F
UPCASX	RTS

;--- SPI BIOS plugin ------

SETSEC	LDX #SEC		;sector pointer for p.00 in Accu
	LDA 0,X
	STA SECS
	LDA 1,X
	STA SECS+1
	LDA 2,X
	STA SECS+2
	RTS


READ	JSR SETLBA		;SET LBA = IMGTAB + SECS/2
	JSR CHKBLK		;CHECK IF BLOCK VALID
	BCC SD_RD1
	JSR S_READ
	BCS SD_RDX
SD_RD1	LDA SECS
	LSR A
	LDY #0
	BCS SD_RD3
SD_RD2	LDA BLKB,Y
	STA (DMA),Y
	INY
	BNE SD_RD2
	CLC
	RTS

SD_RD3	LDA BLKB+256,Y
	STA (DMA),Y
	INY
	BNE SD_RD3
	CLC
SD_RDX	RTS


WRITE	JSR SETLBA		;WRITE SD card
	JSR CHKBLK
	BCC SD_WR1
	JSR S_READ		;write implicitely
	BCS SD_WRX		;when SD buffer dirty
SD_WR1	LDA SECS
	LSR A
	LDY #0
	BCS SD_WR2
SD_WR3	LDA (DMA),Y
	STA BLKB,Y
	INY
	BNE SD_WR3
	BEQ SD_WR4

SD_WR2	LDA (DMA),Y
	STA BLKB+256,Y
	INY
	BNE SD_WR2	
SD_WR4	LDA #$80
	STA LBA_F		;BLKB dirty
	LDA SECS+2		;is it a dir sector?
	BNE SD_WR5
	LDA SECS+1
	BNE SD_WR5
	LDA SECS
	CMP #SYSSCS+DIRSCS		
	BCS SD_WR5
	JSR SD_WB		;then write SD block immediate
SD_WRX	RTS

SD_WR5	CLC
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
	PLA
	TAX		;restore IMGTAB pointer
	CLC
SETLBA1	LDA LBA,Y	;LBA = IMGTAB + SECS/2
	ADC IMGTAB,X
	STA LBA,Y
	INX
	INY
	CPY #4
	BCC SETLBA1
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
; Write Single Data Block from Std. Block Buffer
; Input:  SD_PB3..SD_PB0 = 32 Bit Command Block Address
; Output: C = 0 Error, C = 1 Read OK
;	  A = Error Code
; *****************************************************************************

SD_WR_BLK_BUF	JSR	INIT_BLKBUF		; set pointer to block buffer
		BEQ	SD_WR_BLK

; *****************************************************************************
; Write Single Data Block from Std. Block Buffer to Logical Address
; Input:  X,Y = Ptr[LO:HI] to 32 Bit LBA Address
; Output: C = 0 Error, C = 1 Data OK
;	  A = Error Code
; *****************************************************************************

SD_WR_LBLK_BUF	JSR	INIT_BLKBUF		; set pointer to block buffer
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
SD_WR_BLK0	LDA	(BLKBUF),Y		; read next byte from buffer
		STY YBUF
		JSR	SPI_OUT		; and write it to the card
		LDY YBUF
		INY				; increment source pointer
		BNE	SD_WR_BLK0		; pointer overflow? No, write next byte
		INC	BLKBUF+1			; yes, increment block buffer page
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


ERROR	STA ERRNO		;ERROR ROUTINE
	JSR CRLF
	LDA #ERRTAB		;SET CCPV
	STA CCPV
	LDA #ERRTAB/256
	STA CCPV+1
	LDY #0			;CHECK ERROR CODE
	LDA (CCPV),Y
ERROR1	BEQ ERROR4		;END OF ERROR ROUTINE
	CMP ERRNO
	BEQ ERROR3
ERROR2	JSR INCCPV		;SKIP ERROR MESSAGE
	BNE ERROR2
	JSR INCCPV
	JMP ERROR1

ERROR3	JSR INCCPV
	PHA
	JSR ERRTYP		;PRINT ERROR TYPE
	JSR INCCPV
	LDA CCPV 		;PRINT ERROR MESSAGE
	LDY CCPV+1
	JSR PRTSTR
	PLA
	BPL ERROR5
	JSR ASKRTY		;ASK FOR RETRY
	LDA ERRNO
	RTS

ERROR4	JSR UETYP		;UNKNOWN ERROR
ERROR5	SEC
	RTS


ERRTYP	LDY #0			;PRINT ERROR TYPE
ERRTY1	LSR A			;SHIFT SOURCE BIT IN C
	BCS ERRTY2
	INY			;X= X+5
	INY
	INY
	INY
	INY
	BNE ERRTY1

ERRTY2	LDA ETYPTB,Y
	BEQ UETYP		;LAST CHR?
	JSR PRTCHR
	INY
	BNE ERRTY2

UETYP	LDA #ERRM1
	LDY #ERRM1/256
	JSR PRTSTR
	LDA ERRNO
	JSR PRTHEX

CRLF	LDA #CRLFM		;PRINTS A NEWLINE
	LDY #CRLFM/256

PRTSTR	LDX #STROUT
	JMP BDOS


PRTCHR	LDX #CONOUT		;PRINTS A CHR
	JMP BDOS


INCCPV	INC CCPV 		;INC CCPV
	BNE INCCP1
	INC CCPV+1
INCCP1	LDA (CCPV),Y
	RTS


ASKRTY	LDA #RTYMES		;RETRY?
	LDY #RTYMES/256
	JSR PRTSTR
	LDX #CONIN
	JSR BDOS
	JSR UPCASE
	CMP #'Y
	BNE ASKRT1
	CLC
	RTS

ASKRT1	SEC
	RTS


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


ERRM1	DB ' Error $',EOT
RTYMES	DB CR,LF,'Retry	(Y/N) ? ',EOT

ETYPTB	DB 'BIOS',$00,'BDOS',$00,'CCP',$00,$00
	DB 'RSX',$00,$00,'USER',$00

ERRTAB	DB $F9,$01,'Invalid Drive',EOT
	DB $DE,$82,'Directory full',EOT
	DB $DD,$82,'File not found',EOT
	DB $DC,$02,'File exists',EOT
	DB $D9,$02,'Invalid FCB',EOT
	DB $D8,$82,'Disk full',EOT
	DB $D6,$82,'File is R/O',EOT
	DB $88,$10,'no SD card found',EOT
	DB $87,$10,'SD card changed',EOT
	DB $86,$10,'SD card write protected',EOT
	DB $85,$10,'Invalid Drive',EOT
	DB $84,$10,'End of Line',EOT
	DB $83,$10,'Too Much Parameters',EOT
	DB $82,$10,'Illegal Parameter',EOT
	DB $81,$10,'Missing Parameter',EOT
	DB $80,$10,'Unknown Command',EOT

	DB $00

;--- Disk Image TABLE ---

IMGTAB	DS 4*4,$00	;Base Sector address of disk images mounted
IMGSTAT	DB $FF,$00,$00,$00	;Flag $FF valid image, $00 no image
SD_TYPE	DB 0		;SD Card Type

;--- buffer for SD CARD

LBA	DS 4,0		;LSB ... MSB
LBA_B	DS 4,$FF
LBA_F	DB $00		;LBA FLAG BIT7 = dirty

;--------------

STATM1	DB CR,LF,'FAT-UTIL	V',VERSION/16+$30,'.',VERSION*$1000/$1000+$30
	DB '	SD-Drive ',EOT
STATM2	DB ':  Sector ',EOT

PROMPT	DB CR,LF,'Command >',EOT

CRLFM	DB CR,LF,EOT

HELPM	DB CLS,'   FAT-UTIL V',VERSION/16+$30,'.',VERSION*$1000/$1000+$30
	DB '			(c) 18.7.2023',CR,LF
	DB 'Command Summary:',CR,LF
	DB '                            '
	DB ' Snnnnnn	read sector nnnnnn',CR,LF
	DB ' D	dump current sector	'
	DB ' Znn	wait for nn/10 s',CR,LF
	DB ' +	read next sector	'
	DB ' -	read last sector',CR,LF
	DB ' R	read current sector	'
	DB ' W	write current sector',CR,LF
	DB ' >	save sector to buffer   '
	DB ' <	get sector from buffer',CR,LF
	DB ' Baddr set buffer to addr	'
	DB ' /nn	repeat nn times',CR,LF
	DB ' CHad,by,by,...	change value at ad with by',CR,LF
	DB ' CAad,<string>	change at ad with string',CR,LF
	DB ' ?	prints this screen	'
	DB ' ',SEMI,'	command separator',CR,LF
	DB ' Ln	logon drive n	        '
	DB ' X	exit to CP/M		',CR,LF
	DB EOT


DMABUF
BLKB = DMABUF+256


	END

