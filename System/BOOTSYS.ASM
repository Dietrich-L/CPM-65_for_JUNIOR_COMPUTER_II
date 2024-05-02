;BOOTSYS.ASM - Junior Computer II BOOT Image loader
;(c) by D. Lausberg

;Bootstrap Loader - rename to BOOT.SYS

;V1.0	23.11.23
;V1.1	26.11.23	minor improvement in readability
;V1.2	08.12.23	debug version
;V1.3	09.01.24	FAT32 & FAT16 support
;V1.4	14.01.24	HEXOUT replaced by HEXDIG
;V1.5	20.02.24	error correction LF's removed, uses COUT
Version = $15

;Parameter

LBA	= $01		;LSB ... MSB

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
TEMP	= $37   	;temp storage
MCNT	= $38

DMA	= $FE		;DMA-Vector
DPH	= $F8		;DPH-VECTOR
NUM32	= $F8     	;LBA vector to 1. Cluster of disc image

BLKBUF	= $DC		;BLKBUF adr for SD	

SD_TYPE	= $1A
IOBASE	= $14
PSTR	= $EA

TPA	= $2000
CCP	= $CC00
BIOS	= $D800

;BIOS COMMANDS

SELDSK	= $09
MOUNT	= $11

;CONSTANTS

MAX_IMG	= $10		;max # of bootable images on SD

CR	= $D
LF	= $A
EOT	= $0

;ERROR CODES

EOF	= $1A

;ROM-BIOS ROUTINES JC II

GETCHR	= $E047		;CIN
STROUT	= $E083		;string out adr in PSTR
HEXDIG	= $E09A		;print HEX in A
PRTCHR	= $E052		;COUT
SD_RD_LBLK = $F462	;load sector in LBA to (BLKBUF)

ROM_MONITOR = $E000	;Monitor cold start


	ORG TPA

BOOT	LDA #BOOTM		;print boot message
	LDY #BOOTM/256
	JSR PRTSTR
	LDY #3			;set LBA to current file
BOOT3	LDA NUM32,Y
	STA LBA,Y
	DEY
	BPL BOOT3
	LDA #3			;load 3 sectors more
	STA MCNT
BOOT4	JSR INCLBA		;load next sector
	LDX #LBA
	LDY #LBA/256
	JSR SD_RD_LBLK		;read 512 bytes from SD to BLKBUF
	BCC B_ERR
	DEC MCNT
	BNE BOOT4
	JSR SEL_BOOT_DISK	;select boot disk
	BCS B_ERR1

	LDA #CCP		;and boot it
	STA BLKBUF
	LDA #CCP/256
	STA BLKBUF+1
BOOT1	JSR INCLBA		;load CCP from sector 1 = next sector
	LDX #LBA
	LDY #LBA/256
	JSR SD_RD_LBLK		;read 512 bytes from SD to CCP
	BCC B_ERR
	LDA BLKBUF+1
	CMP #ROM_MONITOR/256	;all sector read?
	BCC BOOT1
	LDA #IMAGE		;A: in $00..$04, A=0
	JSR MOUNT*3+BIOS	;mount A:
	BCS B_ERR
	JSR SELDSK*3+BIOS	;BIOS SELDSK command
	LDY #17
	LDA SD_TYPE
	STA (DPH),Y		;save SD_TYPE to BIOS
	INY
	LDA IOBASE+1
	STA (DPH),Y		;save SD_TYPE to BIOS
	JMP BIOS		;COLD BOOT

B_ERR1	LDA #ERR1M
	LDY #ERR1M/256
	BNE B_ERR0

B_ERR	LDA #ERRM
	LDY #ERRM/256
B_ERR0	JSR PRTSTR		;print error message

BOOT_X	BRK			;Break to Monitor


;---  CP/M-65 BOOT data area  -------------------

IMG_SIZ	DB 0,0,$10,0	;image size 1 MB
MINUS_2	DB $FE,$FF,$FF,$FF	;-2

;---  MESSAGES  -----------------------------

BOOTM	DB CR,CR,'CP/M-65 for JC-][ Boot Image Loader V'
	DB VERSION/16+$30,'.',VERSION*$1000/$1000+$30,CR,CR,EOT
ERRM	DB CR,'BOOT failed',CR,EOT
ERR1M	DB CR,'no DIR or image found',CR,EOT
SELM	DB CR,CR,'select image: ',EOT

;--- Suboutines -----------------------------

INCLBA	LDX #0			;LBA = LBA+1
INCLBA1	INC LBA,X
	BNE INCLBAX
	INX
	CPX #4
	BCC INCLBA1
INCLBAX	RTS


PRTSTR	STA PSTR		;print message
	STY PSTR+1
	JMP STROUT


SEL_BOOT_DISK
INFO	JSR SET_DIR_INFO	;set directory info parameters
	BCS INFOX
	JSR DISP_INFO		;display files in directory
	BCC DOMOUNT
INFOX	RTS			;C=1 Error

DOMOUNT	LDA #0			;mount image on A:
	STA IMAGE		;save drive
	LDA CNT_I
	BEQ MOUNT4
	LDA #SELM
	LDY #SELM/256
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
	LDA #CR			;print CRLF
	JSR PRTCHR
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
	LDA BLKB+$1BE+4		;OS-Type
	BEQ MOUNT4
	LDY #3
SDIR2	LDA BLKB+$1BE+8,Y
	STA BASE,Y		;BASE = begin of partition
	STA LBA,Y		;LBA = begin of partition
	DEY
	BPL SDIR2
	JSR R_LBA_B		;read sector 0 of partition 1
	BCS SDIRX
	LDA BLKB+$11		;save # dir entries
	STA NDIR
	LDA BLKB+$12
	STA NDIR+1
	LDA BLKB+$0D		;save # sectors/cluster
	STA SEC_CLUS
	LDA BLKB+$0E		;N32 = #reserved sectors
	STA N32
	LDA BLKB+$0F
	STA N32+1
	JSR ADD			;BASE = BASE + N32
	LDA BLKB+$10
	STA NFAT		;#FATs
	LDA BLKB+$16		;N32 = FAT size
	STA N32
	LDA BLKB+$17
	STA N32+1
	ORA N32			;N32 = 0? -> FAT32
	BEQ SDIR4
SDIR3	JSR ADD
	DEC NFAT
	BNE SDIR3
	JSR BASE2LBA		;BASE -> LBA
	JSR R_LBA_B		;read sector 0 of directory
SDIRX	RTS			;C=1 Error

SDIR4	LDA BLKB+$24		;N32 = FAT32 size
	STA N32
	LDA BLKB+$25
	STA N32+1
	LDA BLKB+$26
	STA N32+2
	LDA BLKB+$27
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
DISINF2	CLC			;end of directory
	RTS

DISINFX SEC			;Error
	RTS


DIS_FN	LDA #BLKB		;DIR_FNP = DMA + PNT
	STA DIR_FNP
	LDA #BLKB/256
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
	LDA #CR			;print CRLF
	JSR PRTCHR
	LDA CNT_I
	JSR HEXDIG		;print nr
	LDA #':
	JSR PRTCHR
	JSR PRT_FN
	JSR STO_LBA		;store LBA of 1. sector of the image
	INC CNT_I
	LDA CNT_I
	CMP #MAX_IMG
	RTS			;C=1 end of directory

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
	RTS			;C=1 Error

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

;---------------------------------------------

R_LBA_B	LDA #BLKB/256		;BLKBUF = BLKB
	STA BLKBUF+1
	LDA #BLKB
	STA BLKBUF

R_LBA	LDX #LBA		;read sector in LBA to BLKBUF
	LDY #LBA/256
	JSR SD_RD_LBLK		;read 512 bytes from SD
	BCC R_LBA1
	CLC
	RTS

R_LBA1	SEC			;Error
	RTS	


BLKB 
IMG_LBA	= BLKB+512		;Image LBAs

MEM
	DS $2800-MEM,$00		;SPACE FILLED UP TO 4 SECTORS

TOP
	END
