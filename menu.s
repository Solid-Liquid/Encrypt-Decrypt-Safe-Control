;Project 3 Part 4 - Menu
;Comp 122 TR 4pm Team 2
;Ian Postel, Ian Hinze, Jordan May, Derek Baker, Miguel Sanchez

.extern Encrypt		;Declare a location out outside of this file 
.extern Decrypt
.extern SafeControl

.equ SEG_Test,0xff		;This hex value is the logical OR (|) of all 8 segments of the seg display 
.equ SWI_SEG,0x200
.equ LED_LFT,0x02		;Value for lighting left LED
.equ LED_RGT,0x01		;value for lighting right LED
.equ LED_BTH,0x03		;value for lighting both LEDs
.equ LED_WAIT,55000		;Used as a compare value for filling time to flash the LEDs
.equ SWI_LED,0x201
.equ SWI_LCD_CLR,0x206
.equ SWI_LCD_CHR,0x207
.equ SWI_LCD_INT,0x205
.equ SWI_LCD_STR,0x204
.equ SWI_BlackBtn,0x202
.equ SWI_BlueBtn,0x203
.equ SWI_Exit,0x11


.text
;Code Section:

;Commence test of Embest Board:

ldr r0,=SEG_Test		;set all segments of the 8-segment display to light up		
swi SWI_SEG			;light the segments

mov r6,#0			;r6 counts how many times the led has blinked
Blink:				;loop to test blink the leds
ldr r4,=LED_WAIT		;Set value to cmp to for wait time
mov r5,#0			;set r5 to count up to LED_WAIT
ldr r0,=LED_BTH			;set both LEDs to turn on				
swi SWI_LED			;turn on both LEDs
WaitOn:				;loop to wait while LED is on	
add r5,r5,#1			;inrement r5
cmp r5,r4			;see if r5 has reached LED_WAIT
bne WaitOn			;loop again if hasn't reached LED_WAIT 
mov r5,#0			;reset wait counter
mov r0,#0			;set LEDs to be turned off
swi SWI_LED			
WaitOff:			;loop to wait while LED is off, same as WaitOn
add r5,r5,#1			
cmp r5,r4
bne WaitOff
add r6,r6,#1			;increment how many times LED has blinked
cmp r6,#2			;blink LED two times (cmp to 2)
bne Blink			;blink again if not done
ldr r0,=LED_BTH			;set both LEDs back on until end of test
swi SWI_LED

mov r0,#0			;begin test of printing to LCD screen. set X coord
mov r1,#0			;set y coord
ldr r2,=TestString		;set sample string to be written to LCD
mov r3,#15			;set string to be printed to y locations 0-14
PrintTest:			;loop for printing
swi SWI_LCD_STR			;print single line
add r1,r1,#1			;increment y coord to next line
cmp r1,r3			;see if done printing to last line
blt PrintTest			;loop back if not done

mov r0,#0			;End of test, set r0 to 0 for next two commands
swi SWI_SEG			;turn off the segments of the 8-seg display
swi SWI_LED			;turn off the two LEDs
swi SWI_LCD_CLR			;clear all text from the LCD screen

;End of Test. Begin Menu Functionality:

mov r0,#16
mov r1,#5
ldr r2,=Welcome
swi SWI_LCD_STR			;print "Welcome" string to coords x,y(16,5)
mov r0,#6
mov r1,#6
ldr r2,=PressAny
swi SWI_LCD_STR			;print "PressAny" string to coords x,y(6,6)

PressAnyLoop:			;loop to wait until any key is pressed
swi SWI_BlueBtn			;check if a blue button has been pressed
cmp r0,#0			
bne MainMenu			;if a blue button was pressed (r0 not 0), continue to main menu
swi SWI_BlackBtn		;check if a black button has been pressed
cmp r0,#0
bne MainMenu			;if a black button was pressed (r0 not 0), continue to main menu
bal PressAnyLoop		;infinitely loop until button presssed

MainMenu:			;start of the main menu, place to loop back to

swi SWI_LCD_CLR			;clear any remaining text from the LCD

mov r0,#11
mov r1,#2
ldr r2,=MenuTitle
swi SWI_LCD_STR			;print "MenuTitle" string to coords x,y(11,2)
mov r1,#3
ldr r2,=MenuInstr		
swi SWI_LCD_STR			;print "MenuInstr" string to coords x,y(11,3)
mov r1,#5
ldr r2,=Opt1
swi SWI_LCD_STR			;print "Opt1" string to coords x,y(11,5)
mov r1,#7
ldr r2,=Opt2
swi SWI_LCD_STR			;print "Opt2" string to coords x,y(11,7)
mov r1,#9
ldr r2,=Opt3
swi SWI_LCD_STR			;print "Opt3" string to coords x,y(11,9)
mov r1,#11
ldr r2,=Opt4
swi SWI_LCD_STR			;print "Opt4" string to coords x,y(11,11)

MenuChoice:			;loop to wait until menu choice selected
swi SWI_BlueBtn			;check if a blue button has been pressed
cmp r0,#2						
beq GoToEncrypt			;if button 1 pressed, prepare to open encrypt program (see below)
cmp r0,#4
beq GoToDecrypt			;if button 2 pressed, prepare to open decrypt program (see below)
cmp r0,#8
beq GoToSafe			;if button 3 pressed, prepare to open safe control (see below)
cmp r0,#16
beq Exit			;if button 4 pressed, prepare to exit (see below)
bal MenuChoice			;infinitely loop until button pressed         

GoToEncrypt:
swi SWI_LCD_CLR			;clear the LCD
bl Encrypt			;branch to Encrypt file with a link to return here
mov lr,#0			;set link register to 0 for safety
bal MainMenu			;after returning from link, repeat main menu choices

GoToDecrypt:
swi SWI_LCD_CLR			;clear the LCD
bl Decrypt			;branch to Decrypt file with a link to return here
mov lr,#0			;set link register to 0 for safety
bal MainMenu			;after returning from link, repeat main menu choices 

GoToSafe:
swi SWI_LCD_CLR			;clear the LCD
bl SafeControl			;branch to SafeControl file with a link to return here
mov lr,#0			;set link register to 0 for safety
bal MainMenu			;after returning from link, repeat main menu choices

Exit:
swi SWI_LCD_CLR			;clear the LCD
mov r0,#10
mov r1,#5
ldr r2,=ExitMsg1
swi SWI_LCD_STR			;print "ExitMsg1" string to coords x,y(10,5)
mov r1,#6
ldr r2,=ExitMsg2			
swi SWI_LCD_STR			;print "ExitMsg2" string to coords x,y(10,6)
Confirm:			;loop to confirm exit
swi SWI_BlueBtn			;check if blue button presssed
cmp r0,#0
beq Confirm			;keep looping until a blue button has been pressed (r0 not 0)
cmp r0,#16			;given that a button has been pressed, see if it was 4
bne MainMenu			;if a button other than 4 was pressed, return to mainmenu. Otherwise exit
swi SWI_LCD_CLR			;clear the LCD before exiting
swi SWI_Exit			;end of instructions

.data
;Data Section:

TestString: .asciz "#Test#Test#Test#Test#Test#Test#Test#Test"
	.align
Welcome: .asciz "Welcome!"
	.align
PressAny: .asciz "(Press Any Key to Continue)"
	.align
MenuTitle: .asciz "Main Menu:"
	.align
MenuInstr: .asciz "(Use Keys 1-4):"	 
	.align
Opt1: .asciz "1 - Encryption"
	.align
Opt2: .asciz "2 - Decryption"
	.align
Opt3: .asciz "3 - Safe Control"
	.align
Opt4: .asciz "4 - Exit"
	.align
ExitMsg1: .asciz "    Exit Program?"
	.align
ExitMsg2: .asciz "(Yes = 4, No = Other)"
	.align
