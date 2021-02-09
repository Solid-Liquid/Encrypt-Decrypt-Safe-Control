# Encrypt-Decrypt-Safe-Control
## Team project to implement a virtual safe in ARM Assembly. Also includes password encryption and decryption using a shift cipher.
## For use with ARMSim, as the safe component relies on the Embest Board plugin. 
## Ian Hinze, Ian Postel, Jordan May, Derek Baker, Miguel Sanchez
\
\
**Part-1: Encryption**<br />
This is a simple shift cipher (similar to the Caesar cipher, which shifts by 3 characters). To encrypt a letter/character, this cipher uses the substitution method, which replaces the character/letter or value with another one. For example, to encrypt the word DEF using a shift of 2 positions from the mapping below the encrypted word will be FGH.
\
ABC**DEF**GHIJKLM...
\
ABCDE**FGH**IJKLMNO...
\
\
**Part-2: Decryption**<br />
This is similar to the encryption process with the exception that the shift occurs in the opposite direction of the encryption. For example, if you want to decrypt the cipher text FGH, you must use the same shift value that was used for encryption. For this example, it is 2 positions in the opposite direction, so looking to the FGH in the second row and the corresponding letters in the first row, you will find the text DEF (decrypted value or plain text).
Note: the shift value for part-1(encryption), and part-2(decryption) must be variable that can accept any of the values from 0 to 15 (inclusive).
\
\
**Part-3: Safe Control**<br />
Program the control unit for an electronic safe.
Each time an input key is pressed, the red LEDs should blink to indicate that a key is pressed. For example:
1. If any of the blue keypad keys is pressed both red LEDs must blink.
2. If the left black button is pressed the left red LED must blink
3. If the right black button is pressed the right red LED must blink.<br />

To distinguish the output letter from numbers on eight segment LEDs, you must display the period (“.”) segment. For example, an output of the letter “B” should also have the period displayed but an output of the number “8” should not display a period.<br />

The 8-Segment display and LEDs will show the status of the safe:
 U: unlocked
 L: locked
 P: programming a code
 C: confirming a new code
 F: forgetting an old code
 A: a programming request was successful
 E: programming fault.<br />

The safe starts unlocked. The safe cannot be locked if there are no valid codes.
To lock the safe (this should work at ANY time):
1. press the left black button (assuming you have valid code).
To unlock the safe (This should work ONLY when the safe is locked):
1. Enter a valid code sequence
2. Press the left black button.<br />

To learn a new code (codes must be 4 to 7 hexadecimal digits (buttons) inclusive, and the first digit of the code represents a unique user i.e. no two users can have the same first digit):
1. Press the right black button once
2. 8-segment should show 'P'
3. Enter a new code sequence
4. Press the right black button again.
5. 8-segment should show 'C'
6. Enter the same code sequence
7. Press the right black button a third time.
8. If the code was correct 8-segment displays 'A'
9. If the code was incorrect 8-segment display 'E'<br />

To forget an old code:
1. Press the right black button
2. 8-segment should show 'P'
3. Enter an old code sequence
4. Press the right black button again.
5. 8-segment should show 'F'
6. Enter the same code sequence
7. Press the right black button a third time
8. If the codes match 8-segment displays 'A'
9. If the codes did not match 8-segment displays 'E'<br />
\
\
**Part-4: Menu**<br />
The menu will display list of 3 items on the LCD display of the Embest board simulator screen for the user to select one of them. The list must include:
1. Encrypt
2. Decrypt
3. Safe Control<br />
For the first two options, when either option is selected the menu screen must display a message requesting the user to enter Shift value 0 to 15 (by pressing one of the keys on the keyboard of the plug-in 0x0 to 0xF). Once the shift value is entered the menu program should transfer control to the corresponding program to process the message from corresponding input file, and output the result to the corresponding output file.
If the Safe Control option (the third option) is selected, then the menu program will transfer control to the Safe Control code to do programming and locking/unlocking the safe.
