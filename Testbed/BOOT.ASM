;BOOT.ASM - Junior Computer II Version
;(c) by D. Lausberg

;Bootstrap Lader fuer den CP/M-Bootsector

;V0.1	12.07.23
;V1.0	25.07.23	BIOS MOUNT command
Version = $10

;Parameter

LBA	= $01


DMA	= $FE
PLBA	= $E6		;Pointer to LBA
BLKBUF	= $DC		;BLKBUF adr for SD	

OFFSET	= $58
BOOTBEG	= $600+OFFSET

TPA	= $2000
CCP	= $AC00
BIOS	= $B800

;CONSTANTS

CR	= $D
LF	= $A
EOT	= $0

;ROM-BIOS ROUTINES JC II

PRTCHR = $E044		;BOUT
SD_RD_LBLK = $F462	;load sector in LBA to (BLKBUF)
SD_WR_LBLK = $F495	;save sector in BLKBUF to (BLKBUF)

ROM_MONITOR = $E000	;Monitor cold start

;ERROR CODES

INVDRV	= $F9		;invalid drive
SD_ERROR = $F6
I2CError = $F5
NO_DEV	= $F4
ID_NFND	= $F3

;--------------------------------------------

	ORG BOOTBEG

	JMP BOOT

;---  CP/M-65 BIOS disk image table  -------------------

IMGTAB	DS 4*4		;Base Sector address of disk images mounted
IMGSTAT	DS 4,0		;Flag $FF valid image, $00 no image


;---  MESSAGES  -----------------------------

BOOTM	DB CR,LF,'CP/M-65 for JC-II Bootstrap Loader V'
	DB VERSION/16+$30,'.',VERSION*$1000/$1000+$30,CR,LF,EOT
ERRM	DB CR,LF,'BOOT failed',CR,LF,EOT

;--------------------------------------------

BOOT	LDY #3			;set LBA to current file
BOOT3	LDA (PLBA),Y
	STA LBA,Y
	STA IMGTAB,Y		;also make a copy
	DEY
	BPL BOOT3
	LDA #$FF
	STA IMGSTAT		;make A: valid
	LDA #0
	STA 0

BOOT2	LDA #CCP		;and boot it
	STA BLKBUF
	LDA #CCP/256
	STA BLKBUF+1
BOOT1	LDX #LBA
	LDY #LBA/256
	JSR SD_RD_LBLK		;read 512 bytes from SD to CCP
	BCC B_ERR
	INC LBA
	LDA BLKBUF+1
	CMP #ROM_MONITOR/256	;all sector read?
	BCC BOOT1
	LDY #0
BOOT5	LDA BOOTM,Y		;print boot message
	BEQ BOOT6
	JSR PRTCHR
	INY
	BNE BOOT5

	LDA #0			;A: in $00..$04
	JSR $11*3+BIOS		;mount A:
BOOT6	JMP BIOS		;COLD BOOT

B_ERR	LDY #0
BOOT4	LDA ERRM,Y		;print error message
	BEQ BOOT_X
	JSR PRTCHR
	INY
	BNE BOOT4

BOOT_X	JMP ROM_MONITOR		;and fall back to Monitor


	END
