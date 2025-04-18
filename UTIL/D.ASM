;D.COM   -  DIRECTORY Utility JC II Version
;by D. Lausberg		(c) 1991

;V1.0	16.01.91
;V1.1	 2.11.91	improved disc handling
;V1.2	31.03.95	no disc change on C:
;V1.3	30.12.95	no disc change on drives C: and above
;V1.4	03.07.00	BDOS 2.0 version
;V1.5	04.02.21	correct filesize
;V1.6	29.04.21	no disc change on drives E: and above
;V2.0	24.02.22	sorted DIR
;V2.1	30.07.23	disc change only if implicitly required
;V2.2	27.10.23	error in disk free calc
;V2.3	19.05.24	proper termination via BDOS(0)
;V2.4	18.04.25	/P option
VERSION	= $24

;---- System Constants

DMA     = $FE
DIRBUF	= $FC
DPH	= $F8
FCB1	= $F6
BDOS	= $F0
CCPV	= $E0

;---- PAGE 00 CELLS

DIRPNT	= 0		;DIRECTORY POINTER
CNT	= 1		;COUNTER for PRT
F_CNT	= 2		;FILE COUNTER
BUFPNT	= 3		;FILE BUFFER POINTER
BUFINDP	= 5		;File Buffer Index Pointer
FN1	= 7		;don't switch FN1 & FN2 entries!
FN2	= 9
EX_FLAG	= 11		;exchange flag for bubble sort
RECBUF	= 12		;File REC Buffer
S_FILES	= 14		;sum of filesize selected files
BCD	= 16		;Buffer BCD conversion 3 Bytes
CONV	= 19		;2 bytes buffer for BCD conversion
COL	= 21		;col nr. 0/1
ZFlag	= 22		;flag for leading zero's
ERRNO	= 23		;BUFFER FOR ERROR NUMBER
SPBDIV	= 24		;LOG(2) SPB
C_BUF   = 25		;Buffer for C
DEF_DRV	= 26		;buffer for DEFDRV
SWITCH	= 27		;Bit 7 = /P flag
L_CNT	= 28		;line counter
PNT	= 29

;---- BDOS COMMANDS

BOOT	= $00		;warm Boot
CONIN	= $01		;CONSOLE INPUT
CONOUT	= $02		;CONSOLE OUTPUT
STROUT	= $09		;PRINT STRING
DEFDRV	= $0D		;select default drive
SELDRV	= $0E		;select drive
FIRST	= $11		;GET 1. DIR ENTRY
NEXT	= $12		;GET NEXT DIR ENTRY
GETDRV	= $19		;GET DEFAULT DRIVE
BIOS	= $1A

;---- BIOS COMMANDS

_CONST	= 2
_CHRIN	= 3
_CHROUT	= 4


;---- KONSTANTEN
L_BLOCK	= 15		;# lines per block for /P

FCB_FLG	= 0
FCB_EXT	= 12
FCB_REC	= 15

EOT	= $00
CR	= $0D
LF	= $0A
SP	= $20

NOTFND	= $DD

;----------------------------------------------

	ORG $2000

DIR	LDA #START_MESS		;GREETING MESSAGE
	LDY #START_MESS/256
	JSR PRTSTR
	JSR INIT		;initialize pointers & vars
	BCS DIR4
	LDX #FIRST
	JSR BDOS		;CHECK FOR FILE
	BCC DIR1
DIR4	JSR ERROR
	BCC DIR
	BCS DIRX

DIR1	STY DIRPNT		;read dir to buffer
	JSR SavBDP		;save BUFPNT to BUFDIR & INC BUFDIRP
	LDX #FCB_REC
DIR3	LDY DIRPNT		;STORE DIR INFO TO BUFFER
	LDA (DIRBUF),Y		;BYTE	COMMENT
	LDY #0			;0	FLAGBYTE
	STA (BUFPNT),Y		;1..8	FILENAME
	INC DIRPNT		;9.11	EXT
	JSR INC_BUFPNT		;12	EXTENSION
	DEX			;15	Length
	BPL DIR3
	INC F_CNT
DIR2	LDX #NEXT
	JSR BDOS
	BCC DIR1
	CMP #NOTFND
	BEQ DIR_CONT
	JSR ERROR
	BCC DIR2

DIRX	LDA #END_MESS
	LDY #END_MESS/256
	JSR PRTSTR
	LDA DEF_DRV
	LDX #SELDRV		;LOGIN default DRIVE
	JSR BDOS
	LDX #BOOT		;warm boot
	JMP BDOS

DIR_CONT			;all entries in buffer - continue
	JSR RESBUF		;RESET BUFFER POINTER
	LDA F_CNT
	BNE DIR_P
	LDA #NO_FILE
	LDY #NO_FILE/256
	JSR PRTSTR
	JMP DIRX

DIR_P	JSR DIRSORT		; Sort directory
	JSR RESBUF
	LDA #HEADER
	LDY #HEADER/256		;PRINT HEADER
	JSR PRTSTR
	JSR SET_BUFPNT		;set BUFBNT to filename
	JSR PR_FN		;print Attr & Filename.ext
	JMP DIR_P2

DIR_P1	JSR PR_FILE		;print next Filename if ext=0
DIR_P2	DEC F_CNT
	BEQ DIR_PS
	JSR PR_FILE		;print next Filename if ext=0
	DEC F_CNT
	BEQ DIR_PS
	BNE DIR_P1

DIR_PS	JSR PR_REC		;Print filesize of last file
	LDA #SUM_FILESIZE	;Print total space used
	LDY #SUM_FILESIZE/256
	JSR PRTSTR
	JSR CALC_KB
	JSR PRTDEC
	LDA #PRT_KB
	LDY #PRT_KB/256
	JSR PRTSTR
	JMP DIRX


INIT	LDA #0			;init pointers & vars
	STA F_CNT		;RESET FILE COUNTER
	STA S_FILES		;Reset filesize counter
	STA S_FILES+1
	STA COL
	LDA #L_BLOCK	;set line counter
	STA L_CNT
	JSR RESBUF
	JSR XCH_DSK		;exchange disks if needed
	BCS INITX
INIT4	JSR FCB_CHECK		;check for ?,*
INITX	JSR SET_SW
	RTS


XCH_DSK	LDX #DEFDRV		;set default drive
	JSR BDOS
	STA DEF_DRV
	ADC #$41
	STA DRIVE
	LDY #0			;exchange disks if needed
	LDA (FCB1),Y
	BEQ XCHD1		;if a drive is given in command line
	PHA
	ADC #$40
	STA DRIVE
	CMP #'E			;Check for Drive >= E:
	BCS XCHDSKX
	LDA #XCHGM
	LDY #XCHGM/256		;INSERT DISK
	JSR PRTSTR
	JSR WAITKEY
	JSR CRLF
XCHDSKX	PLA			;login drive
	SEC
	SBC #1
	LDX #SELDRV		;LOGIN Target DRIVE
	JSR BDOS
	BCS XCHGDX
XCHD1	LDY #6+1		;GET SPBDIV
	LDA (DPH),Y
	STA SPBDIV
XCHGDX	RTS


WAITKEY	LDX #BIOS		;WAIT FOR KEY
	LDY #_CHRIN
	JMP BDOS


DIRSORT	JSR SET_BIP		;set Buffer index pointer to last entry
	LDY #0
	STY EX_FLAG		;reset exchange flag
	LDA (BUFINDP),Y
	STA FN1
	INY
	LDA (BUFINDP),Y
	STA FN1+1
DSortL	JSR DEC_BIP
	BCS DSort1
	LDY #0
	LDA (BUFINDP),Y
	STA FN2
	INY
	LDA (BUFINDP),Y
	STA FN2+1
	JSR C_DIR		;compare entries & swap if needed
	JMP DSortL

DSort1	BIT EX_FLAG
	BMI DIRSORT
	RTS


SET_BIP	LDY F_CNT		;set Buffer index Pointer to last entry
	DEY			;F_CNT-1
	TYA
	ASL A			;*2
	TAX
	LDA #BUFDIR/256
	ADC #0
	STA BUFINDP+1
	CLC
	TXA
	ADC #BUFDIR
	STA BUFINDP
	BCC SETBIPX
	INC BUFINDP+1
SETBIPX	RTS


DEC_BIP SEC			;dec Buffer index Pointer by 2
	LDA BUFINDP
	SBC #2
	STA BUFINDP
	BCS DECBIP1
	DEC BUFINDP+1
DECBIP1	LDA #BUFDIR/256		;Check for last entry
	CMP BUFINDP+1
	BNE DECBIP2
	LDA #BUFDIR
	CMP BUFINDP
	BNE DECBIP2
	CLC
DECBIP2	RTS			;C=1 Ready

	
C_Dir	LDY #0			;compare Dir entries
C_DirL	INY
	LDA (FN1),Y
	CMP (FN2),Y
	BEQ CDir1
	BMI SWDIR		;if FN1 < FN2 then switch
	LDA FN2			;FN2 --> FN1
	STA FN1
	LDA FN2+1
	STA FN1+1
	RTS

CDir1	CPY #FCB_EXT+1		;compare FN&ext
	BMI C_DIRL
	RTS

SWDIR	LDY #3			;switch dir entries
SWDIRL	LDA FN1,Y
	STA (BUFINDP),Y
	DEY
	BPL SWDIRL
	LDA #$FF
	STA EX_FLAG		;switch occurred
	RTS


SavBDP	LDA BUFPNT		;save BUFPNT to BUFDIR & INC BUFINDP
	LDY #0
	STA (BUFINDP),Y
	INY
	LDA BUFPNT+1
	STA (BUFINDP),Y
INCBIP	CLC			;BUFINDP+2
	LDA #2
	ADC BUFINDP
	STA BUFINDP
	BCC SavBDPx
	INC BUFINDP+1
SavBDPx	RTS
	

SET_BUFPNT			;set BUFPNT
	LDY #0
	LDA (BUFINDP),Y
	STA BUFPNT
	INY
	LDA (BUFINDP),Y
	STA BUFPNT+1
	RTS


INC_BUFPNT		;BUFPNT+1
	INC BUFPNT
	BNE INC_X
	INC BUFPNT+1
INC_X	RTS


PR_FILE	JSR INCBIP		;Print 1 File entry from DIR
	JSR SET_BUFPNT
	LDY #FCB_EXT
	LDA (BUFPNT),Y
	BEQ PR_FIL1
	JMP ADD_REC		;ext > 0

PR_FIL1	JSR PR_REC		;ext = 0
PR_FN	LDY #FCB_FLG
	LDA (BUFPNT),Y
	JSR PRT_BIT		;FLAG BITS
	JSR PRT_BIT
	JSR PRT_BIT
	JSR PRT_BIT
	JSR PRTSP
	JSR INC_BUFPNT
	LDA #8
	JSR PRT			;FILENAME
	LDA #'.
	JSR PRTCHR
	LDA #3
	JSR PRT			;EXT
	JSR PRT2SP
	LDY #FCB_REC-FCB_EXT
	LDA (BUFPNT),Y		;RECORDS
	LDX #0			;set recbuf = rec
	STX RECBUF+1
	STA RECBUF
ADD_SF	LDX #0
	STX C_BUF		;reset C_BUF
	LDX SPBDIV
ADDSF3	LSR A			;add rec to S_Files in kb
	ROL C_BUF		;Records / SPBDIV+1 = Blocks
	DEX
	BPL ADDSF3
	CLC
	LDX C_BUF
	BEQ ADDSF1
	SEC
ADDSF1	ADC #0
	ADC S_FILES
	STA S_FILES
	BCC ADDSF2
	INC S_FILES+1
ADDSF2	RTS


ADD_REC	LDY #FCB_REC
	LDA (BUFPNT),Y
	PHA
	CLC
	ADC RECBUF
	STA RECBUF
	BCC ADDREC1
	INC RECBUF+1
ADDREC1	PLA
	JMP ADD_SF


CALC_KB	LDX SPBDIV		;calc blk -> kBytes
	DEX
	BEQ CALCKB1
CALCKB3	DEX
	BEQ CALCKB2
	ASL S_FILES		;*2
	ROL S_FILES+1
	BCC CALCKB3

CALCKB1	LSR S_FILES+1		;0.5 kB blocks
	ROR S_FILES
	BCC CALCKB2
	INC S_FILES		;round .5 kB
CALCKB2 LDA S_FILES
	LDY S_FILES+1
	RTS


PRT	STA CNT
PRT1	LDY #0
	LDA (BUFPNT),Y
	JSR PRTCHR
	JSR INC_BUFPNT
	DEC CNT
	BNE PRT1
	RTS

PR_REC	LDA #0		;print recbuf
	STA ZFlag
	LDA RECBUF+1
	JSR PRTHEX
	DEC ZFlag
	LDA RECBUF
	JSR PRTHEX
	LDA RECBUF
	AND #%00000111
	PHA
	LSR RECBUF+1
	ROR RECBUF
	LSR RECBUF+1
	ROR RECBUF	
	LSR RECBUF+1
	ROR RECBUF
	PLA
	BEQ PRREC2
	INC RECBUF
	BNE PRREC2
	INC RECBUF+1
PRREC2	LDA RECBUF
	LDY RECBUF+1
	JSR PRTDEC
	LDA COL
	BNE PRREC1
	INC COL
	JSR PRT2SP
	JSR PRT2SP
	RTS

PRREC1	DEC COL
	DEC L_CNT
	BPL PRRECX
	LDX #L_BLOCK
	STX L_CNT
	BIT SWITCH
	BPL PRRECX
	PHA
	JSR WAITKEY
	PLA
PRRECX	JSR CRLF
	RTS


PRTDEC	STA CONV	; Convert 2 byte binary in A/Y to 3 byte BCD
	STY CONV+1
	SED
	LDA #0		; Ensure the result is clear
	STA BCD+0
	STA BCD+1
	STA BCD+2
	STA ZFlag
	LDX #16		; The number of source bits

CNVBIT	ASL CONV	; Shift out one bit
	ROL CONV+1
	LDA BCD+0	; And add into result
	ADC BCD+0
	STA BCD+0
	LDA BCD+1	; propagating any carry
	ADC BCD+1
	STA BCD+1
	LDA BCD+2	; ... thru whole result
	ADC BCD+2
	STA BCD+2
	DEX		; And repeat for next bit
	BNE CNVBIT
	CLD		; Back to binary
	LDY #2
PRTDEC1	LDA BCD,Y
	JSR PRTHEX
	DEY
	BPL PRTDEC1
	RTS


PRT_BIT	ASL A
	PHA
	LDA #'0
	BCC PR1
	LDA #'1
PR1	JSR PRTCHR
	PLA
	RTS


RESBUF	LDA #BUF
	STA BUFPNT		;SET BUFFER POINTER
	LDA #BUF/256
	STA BUFPNT+1
	LDA #BUFDIR
	STA BUFINDP
	LDA #BUFDIR/256
	STA BUFINDP+1
	RTS
	

FCB_CHECK
	LDY #1
	LDA (FCB1),Y		;CHECK FOR ARGUMENT
	CMP #'/			;switch found with no argument?
	BEQ FCB_3
	CMP #SP			;no argument?
	BNE FCB_1
FCB_3	LDA #'?			;SET FCB1 TO *.*
	LDY #11
FCB_2	STA (FCB1),Y
	DEY
	BNE FCB_2
FCB_1	CLC
	RTS


SET_SW	LDY #0
	LDA (DMA),Y		;CHECK FOR SWITCH
	STA PNT
SETSW3	INY
	CPY PNT
	BCS SETSW2
	LDA (DMA),Y
	CMP #'/			;SWITCH?
	BNE SETSW3
	INY
	CPY PNT
	BCS SETSW2
	LDA (DMA),Y		;GET SWITCH
	LDX #0
SETSW4	CMP SWTAB,X
	BEQ SETSW5
	INX
	INX
	CPX #SWTABX-SWTAB
	BCC SETSW4
SETSW2	LDA #0
	STA SWITCH
	CLC
	RTS

SETSW5	INX
	LDA SWTAB,X
	ORA SWITCH
	STA SWITCH
	CLC
	RTS

;========= Error Routine ===========

ERROR	STA ERRNO	;ERROR ROUTINE
	JSR CRLF
	LDA #ERRTAB	;SET CCPV
	STA CCPV
	LDA #ERRTAB/256
	STA CCPV+1
	LDY #0  	;CHECK ERROR CODE
	LDA (CCPV),Y
ERROR1	BEQ ERROR4	;END OF ERROR ROUTINE
	CMP ERRNO
	BEQ ERROR3
ERROR2	JSR INCCPV	;SKIP ERROR MESSAGE
	BNE ERROR2
	JSR INCCPV
	JMP ERROR1

ERROR3	JSR INCCPV
	PHA
	JSR ERRTYP	;PRINT ERROR TYPE
	JSR INCCPV
	LDA CCPV	;PRINT ERROR MESSAGE
	LDY CCPV+1
	JSR PRTSTR
	PLA
	BPL ERROR5
	JSR ASKRTY	;ASK FOR RETRY
	LDA ERRNO
	RTS

ERROR4  JSR UETYP	;UNKNOWN ERROR
ERROR5  SEC
	RTS


ERRTYP  LDY #0  	;PRINT ERROR TYPE
ERRTY1  LSR A   	;SHIFT SOURCE BIT IN C
	BCS ERRTY2
	INY		;X= X+5
	INY
	INY
	INY
	INY
	BNE ERRTY1

ERRTY2  LDA ETYPTB,Y
	BEQ UETYP	;LAST CHR?
	JSR PRTCHR
	INY
	BNE ERRTY2

UETYP   LDA #ERRM1
	LDY #ERRM1/256
	JSR PRTSTR
	LDA ERRNO
	JSR PRTHEX

CRLF	LDA #CRLFM	;PRINTS A NEWLINE
	LDY #CRLFM/256

PRTSTR  LDX #STROUT
	JMP BDOS


PRT2SP  JSR PRTSP
PRTSP   LDA #SP
PRTCHR  LDX #CONOUT	;PRINTS A CHR
	JMP BDOS


INCCPV  INC CCPV	;INC CCPV
	BNE INCCP1
	INC CCPV+1
INCCP1  LDA (CCPV),Y
	RTS


ASKRTY  LDA #RTYMES	;RETRY?
	LDY #RTYMES/256
	JSR PRTSTR
	LDX #CONIN
	JSR BDOS
	CMP #'y
	BEQ ASKRT1
	CMP #'Y
	BEQ ASKRT1
	SEC
	RTS

ASKRT1  CLC
	RTS


PRTHEX  PHA		;PRINTS A HEX NUMBER
	LSR A
	LSR A
	LSR A
	LSR A
	JSR PRTNIB	;PRINT NIBBLE
	PLA
	AND #$0F

PRTNIB  BIT ZFlag	;Print leading Zero's?
	BMI PRTNI2
	CMP #0
	BEQ PRTSP
	DEC ZFlag
PRTNI2	CMP #$0A
	BCC PRTNI1
	ADC #6
PRTNI1  ADC #$30
	JSR PRTCHR
	RTS

;--- Tables ---

SWTAB	DB 'P',$80,'p',$80
SWTABX

;======   MESSAGES  ======

ERRM1   DB ' Error $',EOT
RTYMES  DB CR,LF,'Retry  (Y/N) ? ',EOT

ETYPTB  DB 'BIOS',$00,'BDOS',$00,'CCP',$00,$00
	DB 'RSX',$00,$00,'USER',$00

ERRTAB  DB $FD,$81,'Drive not ready',EOT
	DB $F9,$01,'Invalid Drive',EOT
	DB $DD,$82,'File not found',EOT
	DB $DC,$02,'File exists',EOT
	DB $D9,$02,'Invalid FCB',EOT

	DB $00

CRLFM	DB CR,LF,EOT

START_MESS
	DB CR,LF,'D.COM V',VERSION/16+$30,'.',VERSION*$1000/$1000+$30
	DB '      (c) D.Lausberg',CR,LF
	DB 'Usage d [d:][filename.ext][/p(ause)]]',CR,LF,EOT
HEADER	DB CR,LF,'Attr filename.ext   rec    kB    '
	DB 'Attr filename.ext   rec    kB'
	DB CR,LF,EOT
SUM_FILESIZE
	DB CR,LF,CR,LF,'total diskspace used ',EOT
PRT_KB	DB ' kB',EOT
END_MESS
	DB CR,LF,CR,LF,'Directory finished',CR,LF,CR,LF,EOT
NO_FILE	DB CR,LF,'no file',CR,LF,EOT
XCHGM	DB CR,LF,'Insert disc to drive '
DRIVE	DB 'B:',CR,LF,'and press any key ',CR,LF,EOT

BUFDIR

BUF	= BUFDIR+512

	END
