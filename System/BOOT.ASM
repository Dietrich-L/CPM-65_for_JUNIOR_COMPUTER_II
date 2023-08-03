;BOOT.ASM - Junior Computer II Version
;(c) by D. Lausberg

;Bootstrap Lader fuer den CP/M-Bootsector

;V0.1	12.07.23
;V1.0	25.07.23	BIOS MOUNT command
;V1.1	26.07.23	;$CC00 version
;V1.2	27.07.23	;code improvements
;V1.3	03.08.23	;saves SD_TYPE in DPH
Version = $13

;Parameter

DRIVE	= $00
LBA	= $01		;LSB ... MSB
LBA_B	= $05


DMA	= $FE		;DMA-Vector
DPH	= $F8		;DPH-VECTOR
NUM32	= $F8     	;LBA vector to 1. Cluster of disc image

BLKBUF	= $DC		;BLKBUF adr for SD	

SD_TYPE	= $1A

TPA	= $2000
CCP	= $CC00
BIOS	= $D800

;BIOS COMMANDS

SELDSK	= $09
MOUNT	= $11

;CONSTANTS

CR	= $D
LF	= $A
EOT	= $0

;ROM-BIOS ROUTINES JC II

PRTCHR = $E044		;BOUT
SD_RD_LBLK = $F462	;load sector in LBA to (BLKBUF)

ROM_MONITOR = $E000	;Monitor cold start


	ORG TPA

BOOT	LDY #3			;set LBA to current file
BOOT3	LDA NUM32,Y
	STA LBA,Y
	STA LBA_B,Y		;also make a copy
	DEY
	BPL BOOT3

BOOT2	LDA #CCP		;and boot it
	STA BLKBUF
	LDA #CCP/256
	STA BLKBUF+1
BOOT1	JSR INCLBA		;load CCP from sector 1 = next sector
	LDX #LBA_B
	LDY #LBA_B/256
	JSR SD_RD_LBLK		;read 512 bytes from SD to CCP
	BCC B_ERR
	LDA BLKBUF+1
	CMP #ROM_MONITOR/256	;all sector read?
	BCC BOOT1
	LDY #0
BOOT5	LDA BOOTM,Y		;print boot message
	BEQ BOOT6
	JSR PRTCHR
	INY
	BNE BOOT5

BOOT6	STA DRIVE		;A: in $00..$04, A=0
	JSR MOUNT*3+BIOS	;mount A:
	BCS B_ERR
	JSR SELDSK*3+BIOS	;BIOS SELDSK command
	LDY #17
	LDA SD_TYPE
	STA (DPH),Y		;save SD_TYPE to BIOS
	JMP BIOS		;COLD BOOT

B_ERR	LDY #0
BOOT4	LDA ERRM,Y		;print error message
	BEQ BOOT_X
	JSR PRTCHR
	INY
	BNE BOOT4

BOOT_X	JMP ROM_MONITOR		;and fall back to Monitor


INCLBA	LDX #0			;LBA = LBA+1
INCLBA1	INC LBA_B,X
	BNE INCLBAX
	INX
	CPX #4
	BCC INCLBA1
INCLBAX	RTS

;---  MESSAGES  -----------------------------

BOOTM	DB CR,LF,'CP/M-65 for JC-II Boot Loader V'
	DB VERSION/16+$30,'.',VERSION*$1000/$1000+$30,CR,LF,EOT
ERRM	DB CR,LF,'BOOT failed',CR,LF,EOT

;--------------------------------------------


	END
