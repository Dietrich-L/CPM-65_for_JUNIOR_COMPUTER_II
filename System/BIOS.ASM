;CPM-65 BIOS for JC II

;D. LAUSBERG	(C) 1987

;V0.1	06.07.23	JC II version, erster Anlauf
;V0.2	25.07.23	error corrections & mount function
;V0.3	29.07.23	error correction in SETLBA
;V0.4	02.08.23	error correction MODE adr
;V0.5	05.08.23	saves IOBASE
;V0.6	14.08.23	MOUNT error corrected
;V0.7	13.09.23	no IRQs
;V0.8	14.01.24	error correction
;V0.9	25.04.24	$FC & $FD buffered
;V1.0	29.04.24	$1A buffered
;V1.1	17.05.24	switch to STD ROM routines,CONST corrected
;V1.2	07.12.24	changes for BIOS ROM V1.1.4
;V1.3	13.12.24	changes for VDU ROM software
;V1.4	10.06.25	CONST fixed, RDTIME, CMDDV added
;V1.5	04.09.25	MOUNT expanded for Get IMG_LBA
;V1.6	27.11.25	IRQ routine ROM independent

VERSION	= $16		;VERSION NUMBER

;FORMAT	SD	1024 KBYTES/DISK

;=====================================

;PAGE 00 CELLS

DMAV	= $FE		;DMA-VECTOR
DIRBFV	= $FC		;DIRBF-VECTOR
BLKB	= $FA		;BIOS Block Pointer
DPHV	= $F8		;DPH-VECTOR
JPBDOS	= $F0
MODE	= $DB		;SD Mode byte 0 byte mode; <>0 block mode
TICKCNT	= $DA		;Tick counter
IOB	= $14		;IOBASE
FGCB	= $16		;FGCBASE
CARD3B	= $18		;CARD3BASE
TEMP	= $FC
YSAV	= $FD

;SYSTEM CONSTANTS

T2CL	= $18
IFR	= $1D
IER	= $1E		;Interrupt enable register VIA2

BLKBUF	= $600		;default buffer

FGCBASE	= $1000		;FGC card @ K4 = $1000

STOACC	= $1A77		

BRKUSR	= $1A78
IRQUSR	= $1A7C
IRQVECT	= $1A7E		;IRQ vector

CCP	= $CC00
BEGIN	= $D800

ROM_MONITOR = $E000	;Monitor cold start
CGET = $E04D		;CGET
ROM_CONIN = $E047	;CIN
ROM_CONOUT = $E044	;BOUT
ROM_READTIME = $E2DE
CMDPDEV = $E0B7
CMDDEV	= $E0BA
ROMIRQ	= $F315

; Device IDs *******************************************************************

NULL_ID	= $00		; the NULL device
FDD1_ID = $22		; Floppy drive 1 device ID
FDD2_ID = $23		; Floppy drive 2 device ID
SDC1_ID	= $24		; SD on I/O card

; Device Command Constants ****************************************************

CMD_INIT = 0		;init SD card

CMD_BOOT = 36		;boot from SD
CMD_READ_BUF = 37
CMD_WRITE_BUF = 38

;CONTROL CODES

BREAKC	= $03		;BREAK CODE
CLS	= $0C		;CLEAR SCREEN

BIT_ABS	= $2C		;code byte BIT ABS

;ERROR CODES

INVDRV	= $F9		;invalid drive

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
	JMP CONIN		; 03
	JMP CONOUT		; 04
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
	JMP RDTIME		; 12
	JMP CMDDV		; 13

;========== DATA AREA =============
;--- Disk Image TABLE ---

IMGTAB	DS 4*4,0	;Base Sector address of disk images mounted
IMGSTAT	DS 4,0		;Flag $FF valid image, $00 no image

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
SD_TYPE	DB 0		;SD card type
IOBASEH	DB 0		;IOBASE high byte
CARD3BASEH DB 0		;CARD3BASE high byte

BAT	DB %11110000	;Block Allocation Table Drive A-D
	DS BATSIZ	;max. 1 page

DRIVE	DB 0		;active drive

SECS	DS 4,0		;CPM-65 sector #, Byte 4 is not used

;--- buffer for SD CARD

LBA	DS 4,0		;LSB ... MSB
LBA_B	DS 4,$FF
LBA_F	DB 0		;LBA FLAG BIT7 = dirty

;==================================

BOOT	SEI		;no IRQ's allowed
	LDA #$4C	;SET JMP BDOS
	STA JPBDOS
	LDA #CCP
	STA JPBDOS+1
	LDA #CCP/256
	STA JPBDOS+2
	LDA #CPMIRQ	;set CPM-65 IRQ vector to BIOS IRQ
	STA IRQVECT
	LDA #CPMIRQ/256
	STA IRQVECT+1
	LDY #18		;set IOBASE from BIOS
	LDA (DPHV),Y
	STA CPMIRQL+2	;patch IOBASE adr to CPMIRQ routine
	STA CPMIRQS+2
	LDA #$A0	;deactivate all VIA2 IRQs exept T2
	LDY #IER
	JSR CPMIRQS
	LDA #0		;A: only
	STA DRIVE	;SELECT BOOT DRIVE
	LDX #$0E	;VIA BDOS
	JSR JPBDOS
	CLI
	CLD
	LDX #0 		;WARM BOOT
	JMP JPBDOS


WBOOT	CLI		;IRQ's allowed
	CLD
	LDA DRIVE	;SELECT DEFAULT DRIVE
	JSR SELDSK
	RTS


CONST	LDA CHARBUF
	BNE CONST1	;if there is no byte
	JSR PUSHIOB	;then try to get one
	JSR CGET
	JSR PULLIOB
	BCC CONST2
	STA CHARBUF	;buffer byte in CHARBUF
CONST1	CLC		;C=0, A = byte
	RTS

CONST2	LDA #0		;nothing there
	SEC		;C=1, A=0
	RTS


CONIN	LDA CHARBUF
	BNE CONIN1
	JSR PUSHIOB
	JSR ROM_CONIN
	JSR PULLIOB
CONIN1	PHA
	LDA #0
	STA CHARBUF	;CHARBUF=0, A=chr
	PLA
	RTS


CONOUT	JSR PUSHIOB
	JSR ROM_CONOUT
	JSR PULLIOB
	RTS


LIST	RTS


AUXOUT	RTS

AUXIN	RTS


HOME	RTS


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


READ	JSR PUSH_E0
READ0	JSR SETLBA		;SET LBA = IMGTAB + SECS/2
	BCS SD_RDX
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
	BEQ SD_RD5

SD_RD3	LDA BLKBUF+256,Y
	STA (DMAV),Y
	INY
	BNE SD_RD3
SD_RD5	JSR PULL_E0
	CLC
	RTS

SD_RD4	LDA #CMD_INIT		;on error retry
	JSR CMDDEV
	BCS READ0
	JSR PULL_E0
	SEC
SD_RDX	RTS


WRITE	JSR PUSH_E0
WRITE0	JSR SETLBA		;WRITE SD card
	BCS SD_RDX
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
	JSR PULL_E0
	RTS

SD_WR5	JSR PULL_E0
	CLC
	RTS

SD_WRE	LDA #CMD_INIT		;on error retry
	JSR CMDDEV
	BCS WRITE0
	JSR PULL_E0
	SEC
	RTS


LISTST	RTS



GET_VERSION			;GET VERSION NUMBER

	LDA #VERSION
	RTS


MOUNT	TAX			;mount disk image on SD
	LDA 0,X			;load drive to be mounted
	AND #$3F
	CMP #4			;max A: - D:
	BCS MOU_ERR
	LDA 0,X
	CMP #$40		;bit 6 or 7 set?
	BCS MOUNT2
	TAY			;mount disc image
	LDA #$FF		;set drive byte as valid
	STA IMGSTAT,Y
	TYA
	ASL A			;*4
	ASL A
	TAY
	LDA #4			;4 bytes LBA
MOUNT1	SEC
	PHA
	INX
	LDA 0,X
	STA IMGTAB,Y		;copy LBA block 0
	INY
	PLA
	SBC #1
	BNE MOUNT1
	CLC
	RTS

MOUNT2	CMP #$80		;check for bit 7
	AND #$3F		;clear flag bits
	BCS MOUNT3
	TAY
	LDA IMGSTAT,Y		;LBA invalid
	BEQ MOU_ERR
	TYA			;report LBA mounted
	ASL A			;*4
	ASL A
	TAY
	LDA #4			;4 bytes LBA
MOUNT4	SEC
	PHA
	INX
	LDA IMGTAB,Y		;copy LBA block 0
	STA 0,X
	INY
	PLA
	SBC #1
	BNE MOUNT4
	CLC
	RTS

MOUNT3	TAY			;dismount drive
	LDA #$00		;set drive byte as invalid
	STA IMGSTAT,Y
	CLC
	RTS

MOU_ERR	LDA #INVDRV		;invalid drive #
	SEC
	RTS


RDTIME	PHA			;read RTC A/X/Y = hh/mm/ss
	JSR PUSHIOB
	PLA
	JSR ROM_READTIME
	PHA
	TXA
	PHA
	JSR PULLIOB
	PLA
	TAX
	PLA
	CLC
	RTS


CMDDV	PHA			;send command to device
	TAX
	LDA 0,X			;cmd pointer for p.00 in Accu
	ASL A
	TAX
	LDA CMDLIST,X		;set adr for CMD channnel
	STA CMDJMP+1,X
	LDA CMDLIST+1,X
	STA CMDJMP+2,X
	JSR PUSHIOB
	PLA
	TAX
	LDA 1,X			;get A
	PHA
	LDY 3,X			;get Y
	LDA 2,X			;get X
	TAX
	PLA
CMDJMP	JSR CMDJMP		;self modifying code
	JSR PULLIOB
	RTS

CMDLIST	DW CMDPDEV,CMDDEV	

;====== CPM-65 IRQ ROUTINES =======

CPMIRQ	PHA
	TYA
	PHA
	LDY #IFR
	JSR CPMIRQL		;LDA IFR
	BPL CPMIRQ1
	LDA #$4B
	LDY #T2CL		;restart timer2
	JSR CPMIRQS
	LDA #$41
	LDY #T2CL+1
	JSR CPMIRQS
	LDA TICKCNT		;dec TICKCNT to zero
	BEQ CPMIRQ2
	DEC TICKCNT
CPMIRQ2 PLA
	TAY
	PLA
	RTI

CPMIRQ1	PLA			;no VIA2 IRQ
	TAY
	PLA
	STA STOACC		; save current accumulator
	PLA			; get current processor status in A
	PHA			; and push it back to stack
	AND #$10		; mask break flag
	BNE USRBREAK	; if break flag set, jump to user break handler
	LDA STOACC
	JMP (IRQUSR)	; else jump to user IRQ routine

USRBREAK
	LDA STOACC
	JMP (BRKUSR)

CPMIRQL	LDA $FF00,Y
	RTS

CPMIRQS	STA $FF00,Y
	RTS
	
;====== SUBROUTINES =======

SETLBA	LDX DRIVE
	LDA IMGSTAT,X	;Check for valid image base adr
	BEQ SETLBX
	TXA		;Drive*4 = pnt for base LBA
	ASL A
	ASL A
	TAX
	LDY #2
	CLC
SETLBA0	LDA SECS,Y	;SECS/2
	ROR A
	STA LBA,Y
	DEY
	BPL SETLBA0
	INY		;Y=0
	LDA #4
	STA MODE	;counter for addition
	CLC
SETLBA1	LDA LBA,Y	;LBA = IMGTAB + SECS/2
	ADC IMGTAB,X
	STA LBA,Y
	INX
	INY
	DEC MODE
	BNE SETLBA1
	LDA SD_TYPE	;set mode byte
	STA MODE
	CLC
	RTS

SETLBX	LDA #INVDRV
	SEC
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


S_READ	BIT LBA_F		;SD_READ
	BPL S_READ1		;if buffer dirty
	JSR S_SAVE		;SAVE SD_BUFFER
	BCS S_READX
S_READ1	LDX #LBA		;load LBA to BLKBUF
	LDY #LBA/256
	LDA #CMD_READ_BUF
	JSR CMDDEV
	BCS S_READX
S_READC	SEC
	RTS

SD_WB	LDX #LBA		;Write SD_ block pysically
	LDY #LBA/256
	LDA #CMD_WRITE_BUF
	JSR CMDDEV
	BCC S_READC		;Error

S_READX	LDX #3			;save LBA AND update LBA_FLAG
SD_UPD1	LDA LBA,X
	STA LBA_B,X
	DEX
	BPL SD_UPD1
	LDA #0
	STA LBA_F
	CLC
	RTS


S_SAVE	LDX #LBA_B		;save old buffer to SD
	LDY #LBA_B/256
	LDA #CMD_WRITE_BUF
	JSR CMDDEV
	BCC S_READC
	CLC
	RTS


PUSHIOB	STY Y_BUF
	LDY #ZP_CELL-ZP_IOB-1	;Save page zero cells for CHR-IO
	DB BIT_ABS
PUSH_E0	LDY #ZP_BUF-ZP_IOB-1	;Save page zero cells
	PHA
PUSH_E1	LDX ZP_IOB,Y		;load page zero adr
	LDA 0,X			;load cell content
	STA ZP_BUF,Y		;and save it
	DEY
	BPL PUSH_E1
	INY			;restore IOB & FGCB & CARD3B
	STY IOB
	STY FGCB
	STY CARD3B
	LDA IOBASEH
	STA IOB+1
	LDA #FGCBASE/256	;fix @ $1000
	STA FGCB+1
	LDA CARD3BASEH
	STA CARD3B+1
	LDY Y_BUF
	PLA
	RTS


PULLIOB	STY Y_BUF
	LDY #ZP_CELL-ZP_IOB-1	;restore page zero cells for CHR-IO
	DB BIT_ABS
PULL_E0	LDY #ZP_BUF-ZP_IOB-1	;restore page zero cells
	PHA
	PHP
PULL_E1	LDX ZP_IOB,Y		;load page zero adr
	LDA ZP_BUF,Y		;load cell content
	STA 0,X			;and restore it
	DEY
	BPL PULL_E1
	LDY Y_BUF
	PLP
	PLA
	RTS


ZP_IOB	DB $14,$15,$16,$17,$18,$19,$F1,$FD
ZP_CELL DB $E3,$E2,$E1,$E0,$FC,$DB
ZP_BUF	DS ZP_BUF-ZP_IOB,0

CHARBUF	DB 0			;chr buffer for console IO

Y_BUF	DB 0
	
DMA	

DIRBF	=  DMA+256


	END
