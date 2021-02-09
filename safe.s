;Project 3 Part 3 - Safe Control
;Comp 122 TR 4pm Team 2

.global SafeControl		;declares "SafeControl" for use in an external file


.equ DISP_U,0x7d		;hex value to display "U." on 8seg display (Unlocked)
.equ DISP_L,0x1d  		;hex value to display "L." on 8seg display (Locked)
.equ DISP_P,0xd7		;hex value to display "P." on 8seg display (Programming)
.equ DISP_C,0x9d		;hex value to display "C." on 8seg display (Confirm)
.equ DISP_F,0x97		;hex value to display "F." on 8seg display (Forget)
.equ DISP_A,0xf7		;hex value to display "A." on 8seg display (Accepted)
.equ DISP_E,0x9f		;hex value to display "E." on 8seg display (Errored)
.equ SWI_SEG,0x200		;set 8seg display to r0
.equ LED_LFT,0x02		;Value for lighting left LED
.equ LED_RGT,0x01		;value for lighting right LED
.equ LED_BTH,0x03		;value for lighting both LEDs
.equ LED_WAIT,55000		;Used as a compare value for filling time to flash the LEDs (originally 50k updated to 75k)
.equ SWI_LED,0x201		;engage selected LED
.equ SWI_LCD_CLR,0x206
.equ SWI_LCD_CHR,0x207
.equ SWI_LCD_INT,0x205
.equ SWI_LCD_STR,0x204
.equ SWI_LCD_CLRLine,0x208
.equ SWI_BlackBtn,0x202 	;check black input
.equ SWI_BlueBtn,0x203		;check blue input
.equ SWI_Exit,0x11			;Undergo Critical Existence Failure
.equ NULL,0x81818181

; Known register uses:
; r0 - r2: permanent throwaways
; r3, r4: in Blink, LED blink timer
; r3: in BlueKey, throwaway
; r5: in BlueKey, store input
; r8: initial stack pointer. Always.
; r9: entered password length counter
; PasswordConfirmation1of2 and 2of2 use all registers
; r7: in PassConfirm1 and 2, used to determine if password is added or deleted
; lr is only used by Blink

.text
;Code Section:

SafeControl:			;this is where an external file would branch to
ldr r3,=LinkValue		;going to store value of the link register in LinkValue
str lr,[r3]			;store value of lr (location from outside) to free up lr for loops
mov r0, #DISP_U		;preset safe status to Unlocked
str r0, =Status
ldr r0, =Passcount
cmp r0, #15
movge r0, #0
strge r0, =Passcount


mov r0,#5			;setting up instructions to be printed to LCD
mov r1,#5
ldr r2,=Instruct1
swi SWI_LCD_STR			;print string "Instruct1" to coords x,y(5,5)
mov r1,#7
ldr r2,=Instruct2
swi SWI_LCD_STR			;print string "Instruct2" to coords x,y(5,7)
mov r1,#9
ldr r2,=Instruct3
swi SWI_LCD_STR			;print string "Instruct3" to coords x,y(5,9)
mov r1,#11
ldr r2,=Instruct4
swi SWI_LCD_STR			;print string "Instruct4" to coords x,y(5,11)
mov r1,#12
ldr r2,=Instruct5
swi SWI_LCD_STR			;print string "Instruct5" to coords x,y(5,12)
mov r1,#1
ldr r2,=Instruct6
swi SWI_LCD_STR			;print string "Instruct6" to coords x,y(5,1)
mov r1,#3
swi SWI_LCD_STR			;print string "Instruct6" to coords x,y(5,3)
mov r8,sp			;preset r8 to initial sp. 


Refresh:			;place to return to after pressing a button
ldr r0, =Status			;set 8seg display to current status
swi SWI_SEG			;light up the 8 seg display

InputLoop:			;Main loop for input to the safe
swi SWI_BlackBtn		;check if black button has been pressed
cmp r0,#2			
beq LeftBlackBtn		;if r0=2, go to LeftBlackButton instructions
cmp r0,#1
beq RightBlackBtn		;if r0=1, go to RightBlackButton instrutions
swi SWI_BlueBtn			;check if a blue button has been pressed
cmp r0,#0
bne BlueKey			;if r0 not 0, go to BlueKey instructions
bal InputLoop			;infinitely loop to get input


BlueKey:
mov r5,r0			;store blue key value in r5 to free up r0
ldr r0,=LED_BTH			;set both LEDs to blink
bl Blink			;branch to Blink with a link to return here

ldr r0, =Status 	;If the safe is Unlocked (not Locked or Programming), ignore blue buttons
mov r1, #DISP_U
cmp r0, r1
cmpeq r5, #16		;... Except this one. Exit to menu on 4, but only if we're Unlocked
beq Exit	

ldr r0, =Status 	;(and if Unlcked and not 4) ignore blue buttons
mov r1, #DISP_U
cmp r0, r1
beq Skip

cmp r9,#7			;max digits allowed is 7, see how many we have
bge Skip			;if we are at 7 digits, skip to below
cmp r9, #0			;if no digits entered, store the current stack pointer into r8
moveq r8, sp
add r9,r9,#1			;increment digit count 
stmfd sp!,{r5}			;store which key was pressed on the stack
mov r3,#2			;need #2 for next mul
mul r0,r9,r3			;needed to set x coord to print an asterisk * 			
add r0,r0,#10			;also for x coord
mov r1,#2			;this is the y coord to print to 
mov r2,#42			;42 is ascii for *
swi SWI_LCD_CHR			;print char * to the LCD 
Skip:		
b Refresh			;(otherwise) always branch back to refresh/input loop

@@@@@@@@@@@@@

LeftBlackBtn: ;Lock/Unlock

ldr r0, =Passcount		;load current password count
cmp r0, #0				;and if it's 0, this button does nothing.
movle r0, #DISP_E
swile SWI_SEG
ble EndLeft
cmp r0, #17				;anti-underflow catch
movge r0, #DISP_E
swige SWI_SEG
bge EndLeft

ldr r0, =Status			;If we're locked, try to unlock
cmp r0, #DISP_L
beq Unlock

b SetLocked				;and if we're not locked and we have a password, lock

Unlock:
cmp r9, #4
movlt r0, #DISP_E
swilt SWI_SEG
blt EndLeft

mov sp,r8		;set stack pointer to beginning of password
ldmea sp!, {r0}		;load first password digit, to check the slot number
mov r3,#1			;reg used for comparison (below)
mov r4,#0			;the converted blue key value (below)
mov r5,#2			;value to multiply by (below)
Countl:				;loop to convert blue key value to n number 0-15
cmp r0,r3			;see if we have reached the blue key value (it is in r0)
addne r4,r4,#1			;increment r4 
mulne r3,r5,r3			;multiply up from 2 until we reach blue key value
bne Countl			;loop again if not done
mov r5,#32		
mul r4,r5,r4			;multiply blue key val by 32 (bytes)
;r4 now contains the array position to access in Passwords
mov r10, r4 			;back up r4 in 410
ldr r6,=Passwords

ldr r7, [r6,r4]		;load stored password first value into r7
cmp r7, #0
moveq r0, #DISP_E		;if first value is 0, password DNE. 
swieq SWI_SEG
beq EndLeft		

;if password exists in slot, check it against the stack
mov r3, #1			;use r3 to count pw digits checked
Nextl:
add r4, r4, #4		;increment to next memory location
ldr r7, [r6,r4]		;load next stored pass digit
ldmea sp!, {r0}		;load next stack pass digit
bl NullCheck
cmp r7, r0			;check 'em
movne r0, #DISP_E	;if not dubs, fail
swine SWI_SEG
bne EndLeft
add r3, r3, #1		;if dubs
cmp r3, #7			;check if we've done the whole password
bne Nextl			;And keep looping if we haven't

mov r0, #DISP_U			;And if successful, set status unlocked
str r0, =Status
swi SWI_SEG
b EndLeft

SetLocked:
mov r0, #DISP_L			;set status locked
str r0, =Status
swi SWI_SEG
b EndLeft

EndLeft:
ldr r0,=LED_LFT			;set the left LED to blink
bl Blink			;branch to Blink with a link to return here
mov sp, r8			;reset sp,r9
mov r9, #0
mov r0, #2			;wipe the line of *
swi SWI_LCD_CLRLine
b Refresh

NullCheck:			;Destroy nonexistant password digits
cmp r9, #7
bxeq lr
cmp r3,#4
bxlt lr
cmp r9, #5				;if only 4 numbers
ldrlt r0, =NULL
bxge lr
cmp r9, #6				;if only 5 numbers
ldrlt r0, =NULL
bxge lr
cmp r9, #7				;if only 6 numbers
ldrlt r0, =NULL	;kill the spares
bx lr

@@@@@@@@@@@@@

RightBlackBtn: ;Programming, Confirming, Forgetting
ldr r0, =Status ;check safe state
mov r1, #DISP_L ;if locked, return
cmp r0, r1
beq EndRight

mov r1, #DISP_P ;if not locked or in programming mode, go to programming mode
cmp r0, r1
beq PasswordConfirmation1of2	;If already in P, check it

mov r1, #DISP_F ;if Forgetting or Confirming (yes, check both at once), check if password matches last entry
cmp r0, r1
bge PasswordConfirmation2of2

ProgMode:
mov r0, #DISP_P			;engage P
swi SWI_SEG
str r0, =Status
b EndRight

RightBlackError:
mov r0,#DISP_E		;Display "E." on 8seg, caused by entry error
swi SWI_SEG
mov r1,#DISP_U		;Error sets status back to Unlocked
str r1, =Status
mov r9, #0 			;Error also resets inputs
mov sp,r8
mov r0, #2			;Error also wipes the line of *
swi SWI_LCD_CLRLine
b EndRight

EndRight:
ldr r0,=LED_RGT			;set the right LED to blink
bl Blink			;branch to Blink with a link to return here

mov sp, r8			;reset SP and r9
mov r9, #0
mov r0, #2			;clear *s
swi SWI_LCD_CLRLine
b Refresh			;always branch back to refresh/input loop


PasswordConfirmation1of2: ;store entered password in temp memory slot
cmp r9, #4
blt RightBlackError 	;well if they didn't give us 4 digits we can't check

mov r0, #2			;clear *s
swi SWI_LCD_CLRLine

mov sp,r8		;set stack pointer to beginning of password
ldmea sp!, {r0}		;load first password digit, to check the slot number
mov r3,#1			;reg used for comparison (below)
mov r4,#0			;the converted blue key value (below)
mov r5,#2			;value to multiply by (below)
Count:				;loop to convert blue key value to n number 0-15
cmp r0,r3			;see if we have reached the blue key value (it is in r0)
addne r4,r4,#1			;increment r4 
mulne r3,r5,r3			;multiply up from 2 until we reach blue key value
bne Count			;loop again if not done
mov r5,#32		
mul r4,r5,r4			;multiply blue key val by 32 (bytes)
;r4 now contains the array position to access in Passwords
mov r10, r4 			;back up r4 in 410
ldr r6,=Passwords

ldr r7, [r6,r4]		;load stored password first value into r7
cmp r7, #0
beq NotFound		;if first value is Hex 81, password DNE. Naturally this won't work the first time if the sim doesn't initialize to Hex 81.

;if password exists in slot, check it against the stack
mov r3, #1			;use r3 to count pw digits checked
Next1:
add r4, r4, #4		;increment to next memory location
ldr r7, [r6,r4]		;load next stored pass digit
ldmea sp!, {r0}		;load next stack pass digit
bl NullCheck
cmp r7, r0			;check 'em
bne RightBlackError		;if not dubs, fail
add r3, r3, #1		;if dubs
cmp r3, #7			;check if we've done the whole password
bne Next1			;And keep looping if we haven't

b Found 		;and if we have, and we haven't errored out, that means we have a match

Found:
mov r7, #1		;Set r7 to 1. This register will become the check to see if the pass should be added or deleted.

NotFound:
ldr r3, =PasswordTemp
str r10, [r3,#28]	;store the password's array location at the end of the temp password	
mov sp, r8			;reset stack pointer to load password
ldmea sp!, {r0-r6}		;load entire password stack into registers
bl XORTHINGS			;Screw it need it backwards
cmp r9, #5				;if only 4 numbers
ldrlt r4, =NULL
cmp r9, #6				;if only 5 numbers
ldrlt r5, =NULL
cmp r9, #7				;if only 6 numbers
ldrlt r6, =NULL	;kill the spares

;if 7 digit password don't blank any
;Once full password is in registers,
ldr r10, =PasswordTemp		;store password into temp memory slot
stmia r10, {r0 - r6}
mov sp, r8			;reset SP and r9
mov r9, #0
cmp r7, #1
beq FoundShouldDelete		;Check if entering Forget or Confirm
mov r0, #DISP_C			;enter Confirm
str r0, =Status
swi SWI_SEG
b EndRight			;and return

FoundShouldDelete:
mov r0, #DISP_F			;enter Forget
str r0, =Status
swi SWI_SEG
b EndRight			;and return


PasswordConfirmation2of2: ;check entered password against temp memory slot
cmp r9, #4			;fail if <4 digits
blt RightBlackError
mov r4, #0			;preset memory location increment
mov r3, #0			;preset length counter
ldr r6, =PasswordTemp		;load temp password location
mov sp, r8			;reset sp
Next2:
ldr r7, [r6,r4]		;load next stored pass digit
ldmea sp!, {r0}		;load next stack pass digit
bl NullCheck
cmp r7, r0			;check 'em
bne RightBlackError		;if not dubs, fail
add r3, r3, #1		;if dubs
add r4, r4, #4		;increment to next memory location
cmp r3, #6			;check if we've done the whole password
bne Next2			;And keep looping if we haven't

mov sp, r8			;if successful passwords match, we're done with these. Reset sp and r9.
mov r9, #0

ldr r7, [r6,#28]	;and load the password's main storage location

ldr r0, =Status		;check if we're Confirming or Forgetting
cmp r0, #DISP_F
beq Forget

Store:
ldr r9, =Passwords	;temp load root password address
add r7, r7, r9		;-to get target password address
mov r9, #0			;(reset r9 again)
ldmia r10, {r0-r6}	;copy temp password from storage
stmia r7, {r0-r6}	;shove temp password into main memory
ldr r0, =Passcount	;and increment password count
add r0, r0, #1
str r0, =Passcount	;and re-store
b Accept

Forget:				;Wipe out an existing password
mov r0, #0		;uninitialized
ldr r1, =Passwords
mov r2, r7			;store password memory endpoint
add r2, r2, #28
Destroy:
str r0, [r1,r7]		;Destroy all stored digits.
add r7, r7, #4
cmp r7, r2
ble Destroy			;loop until all gone
ldr r0, =Passcount	;and decrement password count
sub r0, r0, #1
str r0, =Passcount	;and re-store
b Accept

Accept:
mov r0,#DISP_A		;Destruction accepted.
swi SWI_SEG
mov r1,#DISP_U		;set status Unlocked
str r1, =Status
mov r0, #0			;prep to wipe out temp password
mov r2, r10			;store temp pass location in r2
add r2, r2, #28		;change it to end temp pass location
ClearTemp:			;wipe temporary password
str r0, [r10]
add r10, r10, #4
cmp r10, r2
ble ClearTemp		;loop until all gone
b EndRight			;Return to main.


Blink:				
ldr r3,=LED_WAIT		;Set value to cmp to for wait time
mov r4,#0			;set r4 to count up to LED_WAIT				
swi SWI_LED			;activate LEDs based on r0 (set elswhere)
WaitOn:				;loop to wait while LED is on	
add r4,r4,#1			;inrement r4
cmp r4,r3			;see if r4 has reached LED_WAIT
bne WaitOn			;loop again if hasn't reached LED_WAIT 
mov r4,#0			;reset wait counter
mov r0,#0			;set LEDs to be turned off
swi SWI_LED			
bx lr				;return to place where Blink was called from

XORTHINGS:
EOR r0, r0, r6		;Don't want to deal with it. Just swap them.
EOR r6, r0, r6
EOR r0, r0, r6
EOR r1, r1, r5
EOR r5, r1, r5
EOR r1, r1, r5
EOR r2, r2, r4
EOR r4, r2, r4
EOR r2, r2, r4
bx lr


Exit:
swi SWI_LCD_CLR			;clear the LCD before exiting
mov r0,#0
swi SWI_SEG			;clear the 8seg display before exiting
ldr lr,=LinkValue		;address of the link value
ldr lr,[lr]			;store value of LinkValue in lr
cmp lr,#0			;compare link register to 0
bne LinkBack			;if link register not 0 (has an address), goto LinkBack
swi SWI_Exit			;end of instructions
LinkBack:
bx lr				;go back to location in link register


.data
;Data Section:

Status: .byte 0				;Current safe status, and 8seg display

Passcount: .byte 0			;Current number of stored passwords

LinkValue: .word 0		;Holds value of lr used to return from an external call

PasswordTemp: .skip 32		;Temporary password storage, for holding between confirm and forget

Passwords: .skip 512 		;This holds all 16 user passwords for the safe

Instruct1: .asciz "Safe Control:"
	.align
Instruct2: .asciz "Lock/Unlock - Left Black Btn"
	.align
Instruct3: .asciz "Program - Right Black Btn"
	.align
Instruct4: .asciz "Exit - Blue Button #4 when"
	.align
Instruct5: .asciz "       safe is Unlocked"
	.align
Instruct6: .asciz "----------------------------"
	.align

