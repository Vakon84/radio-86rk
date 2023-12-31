; ROM DISK LOADER FOR RADIO-86RK
; TO BE INSTALLED AT 0000H OF ROM DISK
; LOADED USING MONITOR COMMANDS R0,200,0 and G
; RELOCATES ITSELF FROM 0H TO 7400H
LOADER: EQU		7400H	; LOADERS ADDRESS

PRINT:	EQU		0F818H	; MONITOR - PRINT STRING
GETCH:	EQU		0F803H	; MONITOR - GET A KEY
PUTCH:	EQU		0F609H	; MONITOR - PRINT CHARACTER
APPS:	EQU		7     	; NUMBER OF APPLICATIONS

		ORG		LOADER
		LXI		H,0H	; LOADER SOURCE ADDRESS
		LXI		D,LOADER; LOADER DESTINATION ADDRESS
		LXI		B,0200H ; LOADER SIZE
LOADER1:
		MOV		A,M		; A <- (HL)
		STAX	D		; (DE) <- A
		INX		H		; HL = HL + 1
		INX		D		; DE = DE + 1
		DCX		B		; BC = BC - 1
		MOV     A,B   	; A <- B
		ORA     C     	; TEST THAT BOTH A AND C == 0
		JNZ     LOADER1-LOADER ; NOT ZERO, COPY NEXT BYTE
		JMP		MPRINT	; GO TO LOADER, PRINT MENU

MPRINT:	LXI		H,MENU	; PRINT THE CATALOG
MINPUT:	CALL	PRINT
		CALL	GETCH	; GET MENU SELECTION
		CPI		'Z'		; RESET MEMORY TO 0?
		JZ		ZERO
		CPI		'S'		; SAVE EDITOR DATA TO TEMP BUFFER?
		JZ		SAVE
		CPI		'L'		; LOAD EDITOR DATA FROM TEMP BUFFER?
		JZ		LOAD
		SUI		30H		; GET SELECTION NUMBER
		JM		MPRINT	; NOT A DIGIT, SHOW THE MENU AGAIN
		CPI		APPS	; MORE THAN NUMBER OF APPS?
		JNC     MPRINT	; SHOW THE MENU AGAIN
		MOV		B,A		; SAVE SELECTION TO REGISTER B
		ORA		A		; A == 0?
		JNZ		FIND	; FIND APP ENTRY IN THE TABLE
		XRA		A     	; A == 0
		STA		2117H 	; (2117H) <- 0 - CLEAR BASIC PROGRAM?
FIND:	LXI		DE,6	; DE <- 6 - TABLE ENTRY SIZE
		LXI		H,TABLE	; HL <- TABLE OFFSET
		XRA		A		; A <- 0
FIND1:	CMP		B     	; COMPARE TABLE ENTRY# TO SELECTION
		JZ		RUN		; COPY AND RUN APP
		DAD		D		; HL = HL + DE - MOVE TO THE NEXT
		INR		A     	; A = A + 1 - INCREMENT ENTRY#
		JMP     FIND1	; COMPARE AGAIN
RUN:	SPHL			; SP <- HL, LOAD ADDRESSES USING SP
		POP		H		; HL <- APP'S ROM START ADDRESS
		POP		D		; DE <- APP'S ROM END ADDRESS
		POP		B		; BC <- APP'S MEMR LOAD ADDRESS
		DCX		SP		; SP = SP - 1 - MOVE SP BACK TO
		DCX		SP    	; POINT TO APP'S ENTRY POINT
; CALL MONITOR SUBROUTINE TO COPY ROM DISK TO RAM
		CALL	0FA68H
		LXI		H,CLS
		CALL	PRINT
		POP		H		; HL <- APP'S ENTRY POINT
		PCHL			; PC <- HL - RUN THE APP

; LOAD - COPY FILE FROM TEMP BUFFER TO MICRON EDITOR BUFFER
LOAD:	LXI		H,UP2	; HIGHLIGHT SELECTION
		CALL	PRINT
		LXI		H,4A00H	; HL <- TEMP BUFFER OFFSET
		LXI		D,2100H	; DE <- EDITOR'S BUFFER OFFSET
COPY:	LXI     B,28FFH	; BC <- FILE SIZE
COPY1:	MOV		A,M		; A <- (HL)
		STAX	D		; (DE) <- A
		INX		H		; HL = HL + 1
		INX		D		; DE = DE + 1
		DCX		B		; BC = BC - 1
		MOV		A,B		; A <- B
		ORA		C		; TEST THAT BOTH A AND C == 0
		JNZ     COPY1	; NOT ZERO, COPY NEXT BYTE
		JMP     MPRINT	; GO TO THE MENU

; SAVE - COPY FILE FROM MICRON EDITOR BUFFER TO TEMP BUFFER
; CHECKS THAT THE FILE SIZE IS LESS OR EQUAL TO 28FFH
SAVE:	LXI		H,2100H	; HL <- EDITOR'S BUFFER OFFSET
SAVE1:	MOV		A,M		; A <- (HL)
		CPI		0FFH	; CHECK FILE SIZE
		JZ		SAVE2	; FILE SIZE IS OK, COPY
		INX		H		; HL = HL + 1
		MOV		A,H		; A <- H
		CPI		4AH
		JNZ		SAVE1	; CHECK NEXT BYTE
		LXI		H,LARGE	; FILE IS TOO BIG
		JMP		MINPUT	; PRINT ERROR MESSAGE
SAVE2:	LXI		H,UP3	; HIGHLIGHT SELECTION
		CALL	PRINT
		LXI		H,2100H	; HL <- EDITOR'S BUFFER OFFSET
		LXI		D,4A00H	; DE <- TEMP BUFFER OFFSET
		JMP		COPY	; COPY FILE

; ZERO - ZERO USER MEMORY FROM 0000H TO 73FFH
ZERO:	LXI		H,UP1	; HIGHLIGHT SELECTION
		CALL	PRINT
		LXI		H,0		; HL < - 0
ZERO1:	MVI 	M,0		; (HL) <- 0
		INX		H		; HL = HL + 1
		MOV		A,H		; A <- H
		CPI		74H		; COMPARE ADDRES TO 7400H
		JNZ		ZERO1	; ZERO NEXT BYTE
		JMP 	MPRINT	; GO TO THE MENU
UP3		DB		19H		; MOVE CURSOR UP 3 POSITIONS
UP2:	DB		19H		; MOVE CURSOR UP 2 POSITIONS
UP1:	DB		19H,18H,0 ; MOVE UP 1 POSITIONS, MOVE RIGHT
LARGE:	DB		"FILE TOO LARGE",0DH,0
;TABLE OF APPS ADDRESSES
;FORMAT: ROM START, ROM END, RAM START
TABLE:	DW		0200H,21FFH,0		; BASIC
		DW		2200H,31FFH,0		; EDITOR/ASSM
		DW		3200H,41FFH,0		; EDITOR/DIS
		DW		4200H,54FFH,6400H	; DP/DDT
		DW		5500H,5FFFH,0		; XONIX
		DW		6000H,779FH,5800H	; OTHELLO
		DW		77A0H,7DFFH,3000H	; TETRIS
		DW		0,0,0				; ADD MORE APPS HERE
MENU:	DB		1FH,0CH,0AH,"ROM-DISK/32K V3.0-2020"
		DB		0AH,0AH,0DH,"DIR:"
		DB		0DH,0AH,"<0>-BASIC"
		DB		0DH,0AH,"<1>-EDITOR/ASSEMBLER"
		DB		0DH,0AH,"<2>-EDITOR/DISASSEMBLER"
		DB		0DH,0AH,"<3>-DP/DDT"
		DB		0DH,0AH,"<4>-XONIX"
		DB		0DH,0AH,"<5>-OTHELLO"
		DB		0DH,0AH,"<6>-TETRIS"
		DB		0DH,0AH
		DB		0DH,0AH,"<S>-COPY EDITOR TO TEMP BUFFER"
		DB		0DH,0AH,"<L>-COPY TEMP BUFFER TO EDITOR"
		DB		0DH,0AH,"<Z>-ZERO RAM"
		DB		0DH,0AH,0
CLS:	DB		1FH,0
		ORG		75FFH
		DB		0FFH

		END