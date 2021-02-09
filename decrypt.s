@Project 3 Part 2 - Decryption
@Comp 122 TR 4pm Team 2

.global	Decrypt	  		@Declares Decrpyt for use outside this file

.equ	SWI_BlueBtn,0x203	@Checking if blue button is pressed
.equ	SWI_LCD_STR,0x204	@Print to LCD
.equ	SWI_LCD_CLR,0x206 	@Clear the LCD
.equ 	SWI_OPEN,0x66 		@Open a file
.equ 	SWI_CLOSE,0x68 		@Close a file
.equ	SWI_PRCHR,0x00		@Write an ASCII char to STDOUT
.equ	SWI_PRSTR,0x69		@Write a null-ending string
.equ	SWI_PRINT,0x6b		@Write an integer
.equ	SWI_RDINT,0x6c		@Read an integer from a file
.equ	SWI_RDSTR,0x6a		@Read string from file
.equ	STDOUT,1		@Standard output
.equ	SWI_EXIT,0x11		@Stop execution
.equ	SWI_DALLOC,0x13		@Deallocate all heap blocks


.text

Decrypt:	@place to start from for external file


@Start initializing the LCD
MOV	r0,#10
MOV	r1,#4
LDR	r2,=TitleText
SWI	SWI_LCD_STR		@Print "TitleText" string to coords x,y(9,4)

MOV	r0,#3
MOV	r1,#5
LDR	r2,=Options0
SWI	SWI_LCD_STR		@Print "Options0" string to coords x,y(2,5)

mov r0,#7
MOV	r1,#6
LDR	r2,=Options1
SWI	SWI_LCD_STR		@Print "Options1" string to coords x,y(6,6)

mov r0,#10
MOV	r1,#7
LDR	r2,=Options2
SWI	SWI_LCD_STR		@Print "Options2" string to coords x,y(9,7)
@End initializing LCD


@Grab input from EMBEST and store value in  r4
inputloop:			@Loop for getting input for name
	SWI SWI_BlueBtn		@Check if a blue button has been pressed
	CMP r0,#0		@If blue button is pressed, r0 will not be 0
	BEQ inputloop		@Loop again if no button is pressed
	
MOV	r3,#1			@Register used for comparison
MOV	r4,#0			@The value of name
MOV	r5,#2			@Value used to multiply by
CMP r0,#1			@Skip loop if input is 0
BEQ open

count:
	ADDNE	r4,r4,#1	@Increment r4 (n), will be our input value
	MULNE	r3,r5,r3	@Multiply up from 2 until we reach blue key value
	CMP	r3,r0		@Compare value (r3) with input value (r0)
	BNE	count

MOV	r9, r4			@Storing cipher value into r9 for later use
@End input grab


@Open input file
open:
LDR	r0,=InputFileName	@Set name for input file
MOV	r1,#0				@Set Mode to input
SWI	SWI_OPEN				@Open file
BCS	noInputFile
LDR	r1,=InputFileHandle	
STR	r0,[r1]




readline:
	LDR 	r7,[r1]
	LDR 	r1,=Array
	MOV 	r2, #80
	SWI	SWI_RDSTR				@Stores the string into =array
	CMP	r0,#1					@IF one EOF reached?
	BEQ	procstop				@Jump to end of program
	MOV	r5,#0					@r5 is index

	MOV	r8,#0
loop:							@Processes a single char then loops back
	CMP	r0,#1 			@Check if end of line has been reached
	BEQ	openOutput
	LDRB	r4,[r1,r5]		@Loads the character value from =array[r5] into r4
	SUB	r4,r4,r9		@Sub encode value from current char
	ADD	r5,r5,#1		@Increment array index
	CMP	r4,#32			@Lower end of ASCII table
	BGE	addtoarray
	ADD	r4,r4,#95

addtoarray:
	LDR r6, =EncodeArray
	STRB	r4,[r6, r8]
	ADD r8,r8,#1
	SUB r0,r0,#1
	BAL loop
	
print:
	LDR	r0,=OutputFileHandle
	LDR	r0,[r0]
	LDR r1, =EncodeArray
	SWI SWI_PRSTR
	BAL readline
	

	


procstop:
	LDR	r0,=InputFileHandle
	LDR	r0,[r0]
	SWI	SWI_CLOSE
	LDR	r0,=OutputFileHandle
	LDR	r0,[r0]
	SWI	SWI_CLOSE
	SWI	SWI_LCD_CLR			@Clear the LCD Screen
	bal	Exit			
	

noInputFile:
	MOV	r0, #STDOUT
	LDR	r1, =InputFileErrorMsg
	SWI	SWI_PRSTR
	SWI	SWI_LCD_CLR
	bal	Exit
	
openOutput:
	LDR	r0,=OutputFileName	@Set name for output file
	MOV 	r1,#1			@Set mode to output
	SWI	SWI_OPEN
	LDR	r1,=OutputFileHandle
	STR	r0,[r1]
	BAL print
	

Exit:
cmp lr,#0		@compare link register to 0
bne LinkBack		@if link register not 0 (has an address), goto linkback
swi SWI_EXIT		@end instructions
LinkBack:
bx lr			@go back to location in link register

	
.data


InputFileHandle:	.skip	4
InputFileName:		.asciz	"decrypt-in.txt"
OutputFileName:		.asciz	"decrypt-out.txt"
OutputFileHandle:	.word	0
InputFileErrorMsg:	.asciz	"Input file does not exist\r\n"
OutputFileErrorMsg:	.asciz	"Error processing output file\r\n"
ReadErrorMsg:		.asciz	"An unknown error occurred\r\n"
	.align
Array:			.skip	85
	.align
EncodeArray:		.skip	85
	.align
TitleText:		.asciz	"    Decryption:"
Options0:		.asciz  "Ensure that decrypt-in.txt exists"
Options1:		.asciz	"And press a key to choose"
Options2:		.asciz	"A value for n (0-15)"


