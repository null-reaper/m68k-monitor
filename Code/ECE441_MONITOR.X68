*-----------------------------------------------------------
* Title      : Monitor Program
* Written by : Clive Gomes
* Date       : November, 2018
* Description: ECE 441 Final Project
*----------------------------------------------------------


*-----------------------------------------------------------------------------------------------------------
*------------------------------------  START OF MONITOR PROGRAM  -------------------------------------------
*-----------------------------------------------------------------------------------------------------------
    ORG $1000
***************************
***   MONITOR  PROGRAM  ***
***************************
*-----------------------------------------------------------------------------------------------------------
*-------------------------------------------- DATA SPACE ---------------------------------------------------

* Stack Location
STACK EQU $3000

* Terminal Prompt 
TML DC.B 'TUTOR 0>'
TE  DC.B 0

* Input Buffer
INPUT DS.B 30 ; 30 characters max
      DC.B 0
      
* General Purpose Memory Registers (Also Serves As Extra Space In Case Input Is Too Long)
REG_X DC.L 0
REG_Y DC.L 0

* Welcome Message
WELC DC.B 'Welcome To TUTOR, Version 0!'
WE   DC.B  0  

* Thank you Message
THANK DC.B 'Thank You For Using TUTOR!'
TKE   DC.B  0 

*-----------------------------------------------------------------------------------------------------------
*-------------------------------------------- PROGRAM SPACE ------------------------------------------------
START:                  ; first instruction of program  

*** STARTS AT $1030

* Initialize Exception Vectors
    MOVE.L #STACK,$0
    MOVE.L #BUS_ERR,$8
    MOVE.L #ADRS_ERR,$C
    MOVE.L #ILL_INST,$10
    MOVE.L #DIV_ZERO,$14
    MOVE.L #CHK_INST,$18
    MOVE.L #PRIV_VIOL,$20
    MOVE.L #LINE_A,$28
    MOVE.L #LINE_F,$2C
  
* Set Stack Pointer to Top of Stack
    LEA STACK,A7
    
    JSR NEWLINE ; Print Blank Line
    
    JSR WELCOME ; Displays Welcome Message
        
    BRA RUN_MONITOR ; Start Monitor Program  
*-----------------------------------------------------------------------------------------------------------  
RUN_MONITOR
* Monitor Program Main Loop
*
    JSR TERMINAL ; Display Terminal Prompt & Get Input
    JSR CHK_CMD ; Check Entered Command & Branch to Appropriate Subroutine
    
    BRA RUN_MONITOR ; Loop till EXIT Command is Executed
*-----------------------------------------------------------------------------------------------------------
TERMINAL
* Displays Terminal Prompt and Gets User Input    
*
    MOVEM.L D0-D1/A1,-(A7) ; Save Registers to Stack 
    
    JSR NEWLINE ; Print Blank Line
    
* Print TUTOR Prompt
    LEA TML,A1
    MOVE.B #14,D0
    TRAP #15  
    
* Get Input String
    LEA INPUT,A1 ; Input (50 characters max)
    MOVE.B #2,D0
    TRAP #15
     
    MOVEM.L (A7)+,D0-D1/A1 ; Restore Registers from Stack  
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------   
NEWLINE
* Moves Print Cursor to the Next Line
*
    MOVEM.L D0/A1,-(A7) ; Store Registers on Stack
    
    LEA TE,A1 ; Address Starts with null character (To not Print Anything)
    MOVE.B #13,D0 ; Set TRAP Function to Output Null Terminated String Starting at A1
    TRAP #15  
    
    MOVEM.L (A7)+,D0/A1 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
SPACE
* Displays a Blank Space
*
    MOVEM.L D0-D1,-(A7) ; Store Registers on Stack
    
    MOVE.B #$20,D1 ; D1.B = ' ' 
    MOVE.B #6,D0 ; Set TRAP Function to Output character in D1.B
    TRAP #15
    
    MOVEM.L (A7)+,D0-D1 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
QUOTE
* Displays a Double Quote (")
*
    MOVEM.L D0-D1,-(A7) ; Store Registers on Stack
    
    MOVE.B #$22,D1 ; D1.B = Double Quote
    MOVE.B #6,D0 ; Set TRAP Function to Output character in D1.B
    TRAP #15
    
    MOVEM.L (A7)+,D0-D1 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
WELCOME
* Displays Welcome Message
*
    MOVEM.L D0/A1,-(A7) ; Store Registers on Stack
    
* Print Welcome Message
    LEA WELC,A1
    MOVE.B #13,D0
    TRAP #15  
    
    MOVEM.L (A7)+,D0/A1 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
THANKYOU
* Displays ThankYou Message
*
    MOVEM.L D0/A1,-(A7) ; Store Registers on Stack
    
* PrintD ThankYou Message
    LEA THANK,A1
    MOVE.B #14,D0
    TRAP #15  
    
    MOVEM.L (A7)+,D0/A1 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*----------------------------------------------------------------------------------------------------------- 
*-----------------------------------------------------------------------------------------------------------



***************************
*** COMMAND INTERPRETER ***
***************************
*-----------------------------------------------------------------------------------------------------------
*-------------------------------------------- DATA SPACE ---------------------------------------------------

*Input Pointer to Read Input String Saved in Memory
INP_PTR DC.L 0 

* Memory Spaces to Store Parsed Data from Input String
DATA1 DC.L 0
DATA2 DC.L 0
DATA3 DC.L 0 

* Error Message for Invalid Input
ERRC DC.B 'INVALID COMMAND!'
CE   DC.B 0

* Table of Command Names
CMD_N DC.B 'HELP  '
      DC.B 'MDSP  '
      DC.B 'SORTW '
      DC.B 'MM    '
      DC.B 'MS    '
      DC.B 'BF    '
      DC.B 'BMOV  '
      DC.B 'BTST  '
      DC.B 'BSCH  '
      DC.B 'GO    '
      DC.B 'DF    '
      DC.B 'EXIT  '
      DC.B 'UPPER '
      DC.B 'BREV  '
      
* Table of Command Addresses
CMD_A DC.W HELP
      DC.W MDSP
      DC.W SORTW
      DC.W MM
      DC.W MS
      DC.W BF
      DC.W BMOV
      DC.W BTST
      DC.W BSCH
      DC.W GO
      DC.W DF
      DC.W EXIT
      DC.W UPPER
      DC.W BREV
      
*-----------------------------------------------------------------------------------------------------------
*-------------------------------------------- PROGRAM SPACE ------------------------------------------------
CHK_CMD   
* Looks for Entered Command in CMD_N and Calls the Command Subroutine if found
* If Command is not found, Error Message is Displayed  
  
    MOVEM.L D0-D1/A1-A3,-(A7) ; Save Registers to Stack
    MOVE.L A0,$102A  ; Save A0 in memory
    
    LEA CMD_N,A0 ; Start Address of Command Names
    LEA CMD_A,A1 ; Start Address of Command Subroutines
    LEA INPUT,A2 ; Start Address of Input
    LEA INP_PTR,A3 ; Address of Input Pointer
    
* Check for starting space character  
    MOVE.B (A2)+,D1
    CMP.B #$20,D1
    BNE CHK_INV ; If no, then Command is Invalid
    
    MOVE.L A2,(A3) ; Save Start Address of Input Command in INP_PTR
    
* Find Match for First Character
MATCH1 MOVE.L (A3),A2 ; Get Start Address of Input Command in A2
    MOVE.L A0,D0 ; Save Start Address of Matched First Character in D0
    
    CMP.L A0,A1 ; A1 - A0
    BEQ CHK_INV ; If reached end of CMD_T, Command Not Found
    
    MOVE.B (A0)+,D1 ; Get a character from CMD_T to D1 
    CMP.B (A2)+,D1 ; D1 - (A2)
    BNE MATCH1 ; If character doesn't match Input Command character, keep searching
    
* Current State: First character of Command Input Matched
    
MATCH2 MOVE.B (A0)+,D1 ; Get a character from CMD_T to D1

    CMP.B #$20,D1 ; Check if character = ' '
    BEQ AT_END ; If true, then reached end of Command Name
    
    CMP.B (A2)+,D1 ; D1 - (A2)
    BNE MATCH1 ; If character doesn't match Input Command character, search for first character again
    
    CMP.L A0,A1 ; A1 - A0
    BGT MATCH2 ; If not reached end of CMD_T, Command Name matches so far
    BRA CHK_INV ; If reached end of CMD_T, Command Not Found
    
AT_END
    CMP.B #0,(A2) ; Check if next character in Input Command is null
    BEQ FOUND ; If yes, Command Found
    CMP.B #$20,(A2) ; Check if next character in Input Command = ' '
    BNE MATCH1 ; If no, search for first character again
    
FOUND
    MOVE.L A2,(A3) ; Save Current Location of Pointer in INP_PTR
    
* Get Address of Command Subroutine    
    LEA CMD_N,A0 ; Start Address of Command Names
    SUB.L A0,D0 ; Find Offset From Start of Command Names Table
* Offset of Command Address from Start of Command Address Table = (Offset from Start of Command Names Table) / 6 * 2
    DIVU #6,D0 ; Offset/6
    MULU #2,D0 ; Offset*2
    ADD.L A1,D0 ; Get Address in Command Address Table  
    MOVE.L D0,A1 ; Set Pointer to that Address
    MOVE.W (A1),A0 ; Get Command Subroutine Start Address in A0
    
    MOVEM.L (A7)+,D0-D1/A1-A3 ; Restore Registers from Stack
    ADD.L #4,A7 ; Throw a Long Word off of Stack
    
    JSR (A0) ; Jump to Command Subroutine
    BRA RUN_MONITOR ; Return from Subroutine
    
CHK_INV JSR INVALID ; Display Error Message    
    
    MOVEM.L (A7)+,D0-D1/A1-A3 ; Restore Registers from Stack
    MOVE.L $102A,A0 ; Restore A0 from Memory
    
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
GET_DATA 
* Parses Data from Input String and Stores it in memory
* Input: Start Address to store result in A0
* D6 = 1 for invalid input

    MOVEM.L D0-D2/A0-A2,-(A7) ; Save Registers to Stack
    
    CLR.L D1 ; Clear Register to Calculate Hex Data
    CLR.L D2 ; Clear Flag (for Hex Operation)
    
    LEA INP_PTR,A1 ; Get Address of Stored Pointer Location
    MOVE.L (A1),A2 ; Get Current Input Pointer Address in A2
    
* Check for starting space character  
    MOVE.B (A2)+,D0
    CMP.B #$20,D0
    BNE GD_INV ; If no, then Data is Invalid
    
    CMP.B #$24,(A2) ; Check if first character = '$' 
    BNE NOTHEX ; If not, proceed assuming the data is decimal
    
    MOVE.L #1,D2 ; If yes, Set Flag (for Hex Operation)
    ADD.L #1,A2 ; Move pointer to the character after '$'
   
* Check if first character is ';'
NOTHEX CMP.B #$3B,(A2) ; Check if next character is ';' 
    BEQ GD_INV ; If yes, then Command is Invalid
    
* Check if character is a number    
ISNUM CMP.B #$3B,(A2) ; Check if next character is ';' 
    BEQ EOD ; If yes, then reached end of data
    CLR.L D0 ; Clear D0
    MOVE.B (A2)+,D0 ; Get a character in D0
    DIVU #$10,D0 ; D0/10
    CMP.W #3,D0 ; Check if 30 <= ASCII character value <= 39
    BEQ HEX ; If character is a number, proceed to conversion

    CMP.L #1,D2 ; Check if number is supposed to be Hex
    BNE GD_INV ; If not, then Number is Invalid
    
* Check if character is a Hex digit
    CMP.W #4,D0 ; Check if character could be between A-F
    BNE GD_INV ; If no, then number is Invalid
    SWAP D0 ; Get remainder in lower word
    CMP.W #0,D0 ; Check if character could be '@'
    BEQ GD_INV ; If yes, then number is Invalid
    CMP.W #6,D0 ; Check if D0 - 6 > 0
    BGT GD_INV ; If yes, then number is Invalid
    
* Number is a valid Hex digit: Remainder is between 1 to 6
    ADD.W #9,D0 ; Remainder becomes 10 to 15 (i.e A to F)
    SWAP D0 ; Put remainder in the upper word   

* Convert the ASCII Data to Hex (Assuming Input Data is Hex)    
HEX LSL.L #4,D1 ; D1*16
    SWAP D0 ; Get remainder in lower word
    ADD.W D0,D1 ; Add remainder to D1
    
    CMP.B #0,(A2) ; Check if next character is ' ' 
    BEQ EOD ; If yes, then reached end of data
    CMP.B #$20,(A2) ; Check if next character is null
    BEQ EOD ; If yes, then reached end of data
    BRA ISNUM ; If no, continue conversion
    
EOD    
    CMP.B #1,D2 ; Check if Flag is Set
    BEQ COMPLETE ; If yes, then operation complete
    JSR HEX_DEC ; If yes, then get the Decimal Equivalent for the Hex number
    
COMPLETE MOVE.L D1,(A0) ; Store Data in (A0)
    MOVE.L A2,(A1) ; Store Current Input Pointer Location
    
    MOVEM.L (A7)+,D0-D2/A0-A2 ; Restore Registers from Stack
    RTS ; Return from Subroutine
    
GD_INV MOVE.B #1,D6 ; Denote Error Message
    MOVEM.L (A7)+,D0-D2/A0-A2 ; Restore Registers from Stack
    RTS ; Return from Subroutine

*-----------------------------------------------------------------------------------------------------------
GET_MODE
* Parses Mode from Input String and Stores it in Memory
* Input: Start Address to store result in A0

    MOVEM.L D0/A0-A2,-(A7) ; Save Registers to Stack
    
    LEA INP_PTR,A1 ; Get Address of Stored Pointer Location
    MOVE.L (A1),A2 ; Get Current Input Pointer Address in A2
    
* Check for ';' Character
    CMP.B #$3B,(A2)+ ; Check if Character is ';'
    BNE INVALID ; If no, then Command is Invalid
    
    CLR.L D0 ; Clear Temporary Register D0
    MOVE.B (A2)+,D0 ; Get Mode ASCII Character in D0
    MOVE.L D0,(A0) ; Store Mode in (A0)
    MOVE.L A2,(A1) ; Store Current Input Pointer Address in INP_PTR
    
    MOVEM.L (A7)+,D0/A0-A2 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
CHK_END
* Checks for <CR> at the End of Command
* Output: D6 = 1 for Invalid Command / D6 = 0 for Valid Command

    MOVEM.L D0/A3-A4,-(A7) ; Store Registers on Stack
    
    LEA INP_PTR,A4 ; Get Address of Input Pointer Location in A4
    MOVE.L (A4),A3 ; Get Current Location of Input Pointer in A3
    MOVE.B (A3),D0 ; Get Character at Current Pointer Location in D0
    BEQ CE_V ; If null, then Command is valid
    
    MOVE.L #1,D6 ; D6 = 1 for Invalid Command
    BRA CK_END ; Operation Complete
    
CE_V CLR.L D6 ; D6 = 0 for Invalid Command

CK_END MOVEM.L (A7)+,D0/A3-A4 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
INVALID 
* Displays Invalid Message
*
    MOVEM.L D0/A1,-(A7) ; Save Registers to Stack
    
* Print "INVALID COMMAND!"
    LEA ERRC,A1
    MOVE.B #13,D0
    TRAP #15
    
    MOVEM.L (A7)+,D0/A1 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------  
HEX_DEC
* Convert Hex Number in D1 to Decimal 
* Used in GET_DATA Subroutine
    MOVEM.L D2-D6,-(A7) ; Save Registers to Stack
    
    CLR.L D5 ; Clear Register to Store Result
    MOVE.L #1,D2 ; Set Starting Multiplier to 1
    
CONV CLR.L D4 ; Clear Temporary Register
    MOVE.L D1,D6 ; Make a Copy of D1 in D6
    ANDI.L #$F,D6 ; D6 = D1%16 (Remainder)
    ADD.L D2,D4 ; Add Multiplier to Temporary Register
    MULU D6,D4 ; Multiply Temporary Register by Remainder
    ADD.L D4,D5 ; Add Product to Result Register
    MULU #10,D2 ; Multiplier = (Multiplier)*16
    LSR.L #4,D1 ; D1 = D1/16 (Quotient)
    BNE CONV ; If Input != 0, continue conversion
    MOVE.L D5,D1 ; If Input = 0, Store Result in D1
     
    MOVEM.L (A7)+,D2-D6 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
*-----------------------------------------------------------------------------------------------------------


 
***************************
***    COMMAND SPACE    ***
***************************
*-----------------------------------------------------------------------------------------------------------
*-------------------------------------------- DATA SPACE ---------------------------------------------------

* Special Memory Spaces (For Use in Subroutines) 
MM_INPUT DC.B ''
SORTW_INPUT DC.B ''

* Messages for BTST (Block Test) Command
BPASS DC.B 'BLOCK TEST PASSED!'
      DC.B 0
BFAIL DC.B 'BLOCK TEST FAILED!'
      DC.B 0 
      
* Messages for BSCH (Block Search) Command      
SFOUND DC.B 'STRING LOCATED!'
      DC.B 0
SLOST DC.B 'STRING WAS NOT FOUND!'
      DC.B 0 

* Lookup Table for HELP Command
INFO DC.B 'HELP: Displays This Message'
     DC.B  0
     DC.B  0
     DC.B 'MDSP: Displays Addresses And Memory Contents'
     DC.B  0
     DC.B 'MDSP <address1> <address2> eg: MDSP $200 $300<CR>'
     DC.B  0
     DC.B 'MDSP <address1> eg: MDSP $200<CR> (Displays 16 bytes)'
     DC.B  0
     DC.B  0
     DC.B 'MM: Modifies Data In Memory'
     DC.B  0
     DC.B 'Default: Displays One Word'
     DC.B  0
     DC.B ';B: Displays One Byte'
     DC.B  0
     DC.B ';W: Displays One Word'
     DC.B  0
     DC.B ';L: Displays One Long Word'
     DC.B  0
     DC.B 'MM <address1>[;size] eg: MM $8;W<CR>'
     DC.B  0
     DC.B  0
     DC.B 'SORTW: Sorts A Block Of Word Size Memory'
     DC.B  0
     DC.B 'Default: Ascending Order'
     DC.B  0
     DC.B ';A: Ascending Order'
     DC.B  0
     DC.B ';D: Descending Order'
     DC.B  0
     DC.B 'SORTW <address1> <address2>[;size] eg: SORTW $50 $60;A<CR>'
     DC.B  0
     DC.B  0
     DC.B 'MS: Sets Data Into Memory'
     DC.B  0
     DC.B 'MS <address> <data> eg: MS $66 "YAY!"<CR>'
     DC.B  0
     DC.B  0
     DC.B 'UPPER: Capitalizes Null Terminated String At Address'
     DC.B  0
     DC.B 'UPPER <address> eg: UPPER $30<CR>'
     DC.B  0
     DC.B  0
     DC.B 'BF: Fills A Block Of Memory'
     DC.B  0
     DC.B 'BF <address1> <address2> <word> eg: BF $50 $60 $345<CR>'
     DC.B  0
     DC.B  0
     DC.B 'BSCH: Searches A Literal String In Memory'
     DC.B  0
     DC.B 'BSCH <address1> <address2> "string" eg: BSCH $50 $60 "Hey"<CR>'
     DC.B  0
     DC.B  0
     DC.B 'BMOV: Moves A Block Of Memory To Another Area'
     DC.B  0
     DC.B 'BMOV <address1> <address2> <address3> eg: BMOV $20 $30 $40<CR>'
     DC.B  0
     DC.B  0
     DC.B 'BTST: Tests Block Of Memory' 
     DC.B  0
     DC.B 'BTST <address1> <address2> eg: BTST $20 $30<CR>'
     DC.B  0
     DC.B  0
     DC.B 'BREV: Reverses Data In A Block Of Memory'
     DC.B  0
     DC.B 'BREV <address1> <address2> eg: BREV $45 $55<CR>'
     DC.B  0
     DC.B  0
     DC.B 'DF: Displays Formatted Registers'
     DC.B  0
     DC.B 'DF  eg: DF<CR>'
     DC.B  0
     DC.B  0
     DC.B 'GO: Start Execution From Given Address'
     DC.B  0
     DC.B 'GO <address> eg: GO $50<CR>'
     DC.B  0
     DC.B  0
     DC.B 'EXIT: Terminates Monitor Program'
     DC.B  0
     DC.B 'EXIT  eg: EXIT<CR>'
     DC.B  0
     DC.B  0
     DC.B  0
     
*-----------------------------------------------------------------------------------------------------------
*-------------------------------------------- PROGRAM SPACE ------------------------------------------------ 
HELP
* Displays HELP Lookup Table
*
    MOVE.L $102A,A0 ; Restore A0 from Memory
    MOVEM.L D0-D2/D6/A1,-(A7) ; Store Registers on Stack
    
    JSR CHK_END ; Check if reached end of input. If not, then Command Invalid
    CMP.B #1,D6 ; Check if D6 = 0
    BEQ H_INV ; If yes, then Command is Invalid
    
    MOVE.B #6,D0 ; Set TRAP Function to Output Character
    CLR.B D2 ; Counter for Number of Null Characters
    
    LEA INFO,A1 ; Load Start Address of HELP Lookup Table in A1
    
H_LOOP MOVE.B (A1)+,D1 ; Get Character in D1
    
    CMP.B #3,D2 ; Look for 3 consecutive null characters
    BEQ H_DONE ; If yes, then Done
    
H_N1 CMP.B #0,D1 ; Check if character is null
    BNE H_N2 ; If no, then don't increment counter
    
    JSR NEWLINE ; Move to Next Line
    
    ADD.B #1,D2 ; Increment Null Counter
    BRA H_N3 ; Jump
    
H_N2 CLR.B D2 ; Reset Null Counter

H_N3 TRAP #15 ; Display Character to Terminal
    BRA H_LOOP ; Loop till 3 consecutive null characters are found

H_DONE MOVEM.L (A7)+,D0-D2/D6/A1 ; Restore Registers from Stack
    RTS ; Return from Subroutine
    
H_INV JSR INVALID ; Display Error Message
    MOVEM.L (A7)+,D0-D2/D6/A1 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
MDSP
* If 2 Addresses Inputted : Displays Addresses and Contents of All Memory Locations Between Addresses
* If 1 Address Inputted : Displays Addresses and Contents of 16 Consecutive Memory Locations Starting at Address

    MOVE.L $102A,A0 ; Restore A0 from Memory
    MOVEM.L D0-D3/D6/A0-A4,-(A7) ; Store Registers on Stack
    
* Get START Address in A1
    LEA DATA1,A0 ; Set Pointer to First Data Save Location
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ MD_INV ; If yes, then Command is Invalid
    MOVE.L (A0)+,A1 ; Get First Address in A1, and then Set Pointer to Second Data Save Location

* Check if Second Address Inputted
    LEA INP_PTR,A4 ; Get Address of Input Pointer Location in A4
    MOVE.L (A4),A3 ; Get Current Location of Input Pointer in A3
    MOVE.B (A3),D0 ; Get Character at Current Pointer Location in D0
    BNE GET2ADR ; If character is not null, then Get Second Address
    MOVE.L A1,A2 ; Copy A1 to A2
    ADD.L #16,A2 ; A2 = A1 + 16
    BRA START_MDSP
    
GET2ADR 
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ MD_INV ; If yes, then Command is Invalid
    MOVE.L (A0),A2 ; Get Second Address in A2
    
START_MDSP  
    JSR CHK_END ; Check if reached end of input. If not, then Command Invalid
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ MD_INV ; Command is Invalid
    
    
MD_LOOP CMP.L A1,A2 ; Check if A2 <= A1
    BLE MD_DONE ; If yes, then MD_DONE
    
    MOVE.L A1,D2 ; Get Address in D2
    MOVE.B #2,D3 ; Set Number of Bytes to Display = 2
    JSR DISPREG ; Output Address

    JSR SPACE ; Output Space Character
    
    MOVE.B (A1)+,D2 ; Get Byte Size Data in D2
    MOVE.B #1,D3 ; Set Number of Bytes to Display = 1
    JSR DISPREG ; Output a Byte in Hex
  
    JSR NEWLINE ; Output Newline Character
    
    BRA MD_LOOP ; Loop While Still in Address Range
    
MD_DONE MOVEM.L (A7)+,D0-D3/D6/A0-A4 ; Restore Registers from Stack
    RTS ; Return from Subroutine
    
MD_INV JSR INVALID ; Display Error Message
    MOVEM.L (A7)+,D0-D3/D6/A0-A4 ; Restore Registers from Stack
    RTS ; Return from Subroutine    
*-----------------------------------------------------------------------------------------------------------  
SORTW
* Sorts Word Size Data in Block of Memory
* Ascending/Descending Depending on Mode

    MOVE.L $102A,A0 ; Restore A0 from Memory
    MOVEM.L D0-D2/D6/A0-A4,-(A7) ; Save Registers to Stack

* Get START Address in A1
    LEA DATA1,A0 ; Set Pointer to First Data Save Location
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ SORT_INV ; If yes, then Command is Invalid
    MOVE.L (A0)+,A1 ; Get First Address in A1, and then Set Pointer to Second Data Save Location
    
* Check if START Address is Even
    MOVE.L A1,D0 ; Get Address in D0
    BTST #0,D0 ; Check if D0 is even
    BNE SORT_INV ; If no, then Address is Invalid

* Get END Address in A2
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ SORT_INV ; If yes, then Command is Invalid
    MOVE.L (A0)+,A2 ; Get Second Address in A2, and then Set Pointer to Third Data Save Location
    
* Check if START Address is Even
    MOVE.L A2,D0 ; Get Address in D0
    BTST #0,D0 ; Check if D0 is even
    BNE SORT_INV ; If no, then Address is Invalid
    
* Check for Order
    LEA INP_PTR,A4 ; Get Address of Input Pointer Location in A4
    MOVE.L (A4),A3 ; Get Current Location of Input Pointer in A3
    
    CMP.B #0,(A3) ; Check if Input String has Ended
    BEQ DEFAULT ; If yes, then Perform Default Operation of Ascending Order
    
    MOVE.L A3,(A4) ; Save Current Input Pointer Location in INP_PTR
  
    JSR GET_MODE ; Get Mode from Input
    MOVE.L (A0),D0 ; Get Third Data in D0
    
    CMP.L #$41,D0 ; Check if Data = 'A'
    BEQ DEFAULT If yes, then Perform Default Operation of Ascending Order
    
    CMP.L #$44,D0 ; Check if Data = 'D'
    BNE SORT_INV ; If no, then Command is Invalid
    
    MOVE.L #1,D2 ; Set Flag for Descending Order
    BRA SORT_START ; Start Sorting Function
  
DEFAULT
    CLR.L D2 ; Reset Flag for Ascending Operation

    JSR CHK_END ; Check if reached end of input. If not, then Command Invalid
    CMP.B #1,D6  ; Check if D6 = 1
    BEQ SORT_INV ; If yes, then Command is Invalid

SORT_START    
    MOVE.L A1,A0 ; Make a Copy of START Address in A0
    CLR.L D0 ; Clear Temporary Register 1
    CLR.L D1 ; Clear Temporary Register 2

OLOOP MOVE.L A1,A3 ; Assuming the First Word is Largest, Set A3 as Pointer
    MOVE.W (A1)+,D0 ; Get Word in D0
    CMP.L A1,A2 ; Check if A2 <= A1
    BLE SORT_END ; If yes, then Sorting Complete
    
ILOOP MOVE.W (A1)+,D1 ; Get Next Word
    CMP.L D1, D0 ; Compare Previous Word with Next Word
    BGE INEXT ; Check if Previous Word >= Next Word
    MOVE.W -(A1),D0 ; Get Larger Word in D0
    MOVE.L A1,A3 ; Set A3 as Pointer to Larger Word

INEXT CMP.L A1,A2 ; Check if A2 <= A1
    BLE ONEXT ; If yes, then Proceed to Next Round of Sorting
    BRA ILOOP ; If no, then Continue Sorting
    
* Swap the Last Number of the Address Range with the Largest Number in the Current Round, then Shorten the Range by a Word
ONEXT MOVE.W (A3),-(A2)
    MOVE.W D1,(A3)
    
    MOVE.L A0,A1 ; Reload START Address in A1
    
    CMP.L A1,A2 ; Check if A2 > A1
    BGT OLOOP ; If yes, then done    
    
SORT_END CMP.L #1,D2 ; Check if Flag is Set
    BNE SORT_DONE ; If yes, then Sorting Complete
    JSR REVERSE ; If no, then change to Decending Order by Reversing Order

SORT_DONE MOVEM.L (A7)+,D0-D2/D6/A0-A4 ; Restore Registers from Stack
    RTS ; Return from Subroutine

SORT_INV JSR INVALID ; Display Error Message
    MOVEM.L (A7)+,D0-D2/D6/A0-A4 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
MM
* Displays Address and Contents of Memory Locations Starting at Inputted Address
* Enter Number at the Terminal to Modify the Memory Contents
* Enter Carriage Return at the Terminal to Go to Next Address Without Modifying the Memory Contents
* Enter Period to Exit MM command loop

    MOVE.L $102A,A0 ; Restore A0 from Memory
    MOVEM.L D0-D4/D6/A0-A4,-(A7) ; Save Registers to Stack
    
* Get START Address in A1
    LEA DATA1,A0 ; Set Pointer to First Data Save Location
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ MM_INV ; If yes, then Command is Invalid
    MOVE.L (A0)+,A2 ; Get First Address in A2, and then Set Pointer to Second Data Save Location
    
* Check if Command String has Ended
    LEA INP_PTR,A3 ; Get Address of Stored Pointer Location
    MOVE.L (A3),A4 ; Get Current Input Pointer Address in A4
    
    CMP.B #0,(A4) ; Check if Character is null
    BEQ MODEW ; If yes, Perform Default Operation, i.e Word Mode
    
* Check for ';' Character
    CMP.B #$3B,(A4) ; Check if Character is ';'
    BNE MM_INV ; If no, then Command is Invalid
    
    MOVE.L A4,(A3) ; Save Current Input Pointer Location in INP_PTR
    
* Check Mode of Operation
    JSR GET_MODE ; Get Mode from Input
    MOVE.L (A0)+,D0 ; Get Mode in D0, and then Set Pointer to Third Data Save Location
    
    CMP.L #$42,D0 ;Check if Mode = 'B'
    BEQ MODEB ; If yes, then Perform Operation in Byte Mode
    
    CMP.L #$4C,D0 ;Check if Mode = 'L'
    BEQ MODEL ; If yes, then Perform Operation in Long Word Mode
    
    CMP.L #$57,D0 ;Check if Mode = 'W'
    BNE MM_INV ; If no, then Command is Invalid
    
MODEW MOVE.L #1,D4 ; D4 = 1 for Word Operation
    BRA MM_START ; Start Memory Modify Operation
MODEB CLR.L D4 ; D4 = 0 for Byte Operation
    BRA MM_START ; Start Memory Modify Operation
MODEL MOVE.L #2,D4 ; D4 = 2 for Long Word Operation

MM_START
    JSR CHK_END ; Check if Command String is at End
    CMP.B #1,D6 ; Check if D6 = 0
    BEQ MM_INV ; If yes, then Command is Invalid

    CLR.L D3 ; Clear Data Input Register
    MOVE.B #16,D2 ; Set Base to 16 for TRAP Function #15
    
MM_LOOP 
* Byte Read Operation 
    CMP.L #0,D4 ; Check if D4 = 0 (for Byte Operation)
    BNE MM_N1 ; If no, then Next
    
    MOVE.B (A2),D2 ; Output a Byte
    MOVE.B #1,D3 ; Size of Output = 1 Byte
    BRA MM_READ ; Perform Read Operation

* Word Read Operation 
MM_N1 CMP.L #1,D4 ; Check if D4 = 1 (for Word Operation)
    BNE MM_N2 ; If no, then Next
    
    MOVE.W (A2),D2 ; Output a Word
    MOVE.B #2,D3 ; Size of Output = 2 Bytes
    BRA MM_READ ; Perform Read Operation
    
* Long Word Read Operation   
MM_N2 MOVE.L (A2),D2 ; Output a Long
    MOVE.B #4,D3 ; Size of Output = 4 Bytes

MM_READ MOVE.L A2,D2 ; Get Address in D2
    MOVE.B #2,D3 ; Size of Output = 2 Bytes
    JSR DISPREG ; Output Address

    JSR SPACE ; Output Space Character
    
    CLR.L D1 ; Clear Output Register 

    JSR DISPREG ; Output Data 

    MOVE.B #$3E,D1 ; Set Character '>' for Output
    MOVE.B #6,D0 ; Set TRAP Function to Output Character in D1.B
    TRAP #15

* Get Input Data
    LEA MM_INPUT,A1 ; Input
    MOVE.B #2,D0
    TRAP #15  
    
* Check for '.'
    CMP.B #$2E,(A1) ; Check if Character = '.'
    BEQ MM_DONE ; If yes, then Memory Modify Complete
    
* Check for null
    CMP.B #0,(A1) ; Check if Character = null
    BNE MM_WRITE ; If yes, then Modify Current Location
    
* Byte Skip Operation 
    CMP.L #0,D4 ; Check if D4 = 0 (for Byte Operation)
    BNE MM_N3 ; If no, then Next
    
    ADD.L #1,A2 Move to Next Byte
    BRA MM_LOOP ; Loop Till '.' is Entered

* Word Skip Operation 
MM_N3 CMP.L #1,D4 ; Check if D4 = 1 (for Word Operation)
    BNE MM_N4 ; If no, then Next
    
    ADD.L #2,A2 Move to Next Word
    BRA MM_LOOP ; Loop Till '.' is Entered
    
* Long Word Skip Operation   
MM_N4 ADD.L #4,A2 Move to Next Long Word
    BRA MM_LOOP ; Loop Till '.' is Entered
    
* Get Input Data in D0

MM_WRITE MOVE.L A1,(A3) ; Save Current Input Pointer Location in INP_PTR 

    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ MM_INV ; If yes, then Command is Invalid
    MOVE.L (A0),D0 ; Get Data in D0
    
* Byte Write Operation 
    CMP.L #0,D4 ; Check if D4 = 0 (for Byte Operation)
    BNE MM_N5 ; If no, then Next
    
    CMP.L #$FF,D0 ; Check if D0 > $FF
    BGT MM_INV ; If yes, then Data Invalid
    
    MOVE.B D0,(A2)+ ; Store Entered Byte in Memory
    BRA MM_WDONE ; Write Operation Done

* Word Write Operation 
MM_N5 CMP.L #1,D4 ; Check if D4 = 1 (for Word Operation)
    BNE MM_N6 ; If no, then Next
    
    CMP.L #$FFFF,D0 ; Check if D0 > $FFFF
    BGT MM_INV ; If yes, then Data Invalid
    
    MOVE.W D0,(A2)+ ; Store Entered Word in Memory
    BRA MM_WDONE ; Write Operation Done
    
* Long Word Write Operation   
MM_N6 MOVE.L D0,(A2)+ ; Store Entered Long Word in Memory

MM_WDONE BRA MM_LOOP ; Loop Till '.' is Entered
    
MM_DONE MOVEM.L (A7)+,D0-D4/D6/A0-A4 ; Restore Registers from Stack
    RTS ; Return from Subroutine
    
MM_INV JSR INVALID ; Display Error Message
    MOVEM.L (A7)+,D0-D4/D6/A0-A4 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
MS
* Stores Hexadecimal/Decimal/ASCII String Input Starting at Inputted Memory Address
*
    MOVE.L $102A,A0 ; Restore A0 from Memory
    MOVEM.L D0-D3/D6/A0-A4,-(A7) ; Save Registers to Stack
    
* Get START Address in A1
    LEA DATA1,A0 ; Set Pointer to First Data Save Location
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ MS_INV ; If yes, then Command is Invalid
    MOVE.L (A0),A1 ; Get First Address in A1

* Look for Space Character followed by a Double Quote
    LEA INP_PTR,A4 ; Get Address of Input Pointer Location in A4
    MOVE.L (A4),A3 ; Get Current Location of Input Pointer in A3
    
    CMP.B #$20,(A3)+ ; Check if Next Character is a Space
    BNE MS_INV ; If no, then Command is Invalid
    
    CMP.B #$22,(A3)+ ; Check if Next Character is a Double Quote
    BNE MS_NUMBER ; If no, then Data is not an ASCII String
    
    MOVE.L A3,A2 ; Store Starting Address of String Input in A2
    
* Check if String Ends with Double Quote
STR_LOOP CMP.B #$22,(A3)+ ; Check if Next Character is a Double Quote
    BEQ STR_END ; If yes, then Reached End of String
    
    CMP.B #0,-(A3) ; Check if Character is null
    BEQ MS_INV ; If yes, then Command is Invalid
    ADD.L #1,A3 ; Go to Next Character
    BRA STR_LOOP ; If no, then Keep Looping 
    
STR_END MOVE.L A3,(A4) ; Store Current Location of Input Pointer in INP_PTR

    JSR CHK_END ; Check if reached end of input. If not, then Command Invalid
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ MS_INV ; If yes, then Command is Invalid
    
    MOVE.L A1,A4 ; Save Start Address in A4
    
* Memory Set Operation with ASCII String Data
MS_LOOP CMP.B #$22,(A2) ; Check if Next Character is a Double Quote
    BEQ MS_END ; If yes, then Memory Set Complete
    
    MOVE.B (A2)+,(A1)+ ; Set Memory
    BRA MS_LOOP ; Loop till End of String 
    
MS_END MOVE.B #0,(A1)+ ; Terminate String With Null Character

* Confirm that Memory Set was Successful

* Display Address
    MOVE.L A4,D2 ; Get START Address in D2
    MOVE.B #2,D3 ; Set Number of Bytes to Display = 2
    JSR DISPREG ; Display Address
    
    JSR SPACE ; Leave a Blank Space
   
* Display String
    JSR QUOTE ; Display Double Quote
    
    MOVE.L A4,A1 ; Get Start Address of Stored String in A1
    MOVE.B #14,D0 ; Set TRAP Function to Output Null Terminated String Starting at A1
    TRAP #15
    
    JSR QUOTE ; Display Double Quote
    
    JSR NEWLINE ; Leave Blank Line
    
    MOVEM.L (A7)+,D0-D3/D6/A0-A4 ; Restore Registers from Stack
    RTS ; Return from Subroutine

* Memory Set Operation with ASCII String Data
MS_NUMBER 
* Get Hexadecimal/Decimal Data
    LEA DATA1,A0 ; Set Pointer to Second Data Save Location
    JSR GET_DATA ; Get Data
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ MS_INV ; If yes, then Command is Invalid
    MOVE.L (A0),D2 ; Get Data in D2
    
    JSR CHK_END ; Check if reached end of input. If not, then Command Invalid
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ MS_INV ; If yes, then Command is Invalid

    CMP.L #$FF,D2 ; Check if D2 > $FF
    BGT MS_1 ; If no, then Data is Larger than a Byte

* Write Byte Size Data to Address
    MOVE.B D2,(A1)
    BRA MS_3 ; Already know Size of Data
    
MS_1 CMP.L #$FFFF,D2 ; Check if D2 > $FFFF
    BGT MS_2 ; If no, then Data is Larger than a Word
    
* Write Word Size Data to Address
    MOVE.W D2,(A1)
    BRA MS_3 ; Already know Size of Data
    
MS_2 
* Write Log Word Size Data to Address
    MOVE.L D2,(A1)
    
MS_3 
* Display Address
    MOVE.L D2,D0 ; Save D2 in D0
    MOVE.L A1,D2 ; Get START Address in D2
    MOVE.B #2,D3 ; Set Number of Bytes to Display = 2
    JSR DISPREG ; Display Address
    MOVE.L D0,D2 ; Restore D2
    
    JSR SPACE ; Leave a Blank Space
 
    CMP.L #$FF,D2 ; Check if D2 > $FF
    BGT MS_4 ; If no, then Data is Larger than a Byte
    
* Confirm that Byte Size Data was Written to Address
    MOVE.B (A1),D2
    MOVE.B #1,D3 ; Number of Bytes to Display = 1
    BRA MS_6 ; Already know Size of Data
    
MS_4 CMP.L #$FFFF,D2 ; Check if D2 > $FFFF
    BGT MS_5 ; If no, then Data is Larger than a Word
    
* Confirm that Word Size Data was Written to Address
    MOVE.W (A1),D2
    MOVE.B #2,D3 ; Number of Bytes to Display = 2
    BRA MS_6 ; Already know Size of Data
    
MS_5
* Confirm that Long Word Size Data was Written to Address
    MOVE.L (A1),D2
    MOVE.B #4,D3 ; Number of Bytes to Display = 4
    
MS_6 JSR DISPREG ; Display Value of Data Written to Memory
    
    JSR NEWLINE ; Leave a Blank Line 
    
    MOVEM.L (A7)+,D0-D3/D6/A0-A4 ; Restore Registers from Stack
    RTS ; Return from Subroutine
       
MS_INV JSR INVALID ; Display Error Message
    MOVEM.L (A7)+,D0-D3/D6/A0-A4 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------   
BF
* Fills Block of Memory With Inputted Word Size Data
*
    MOVE.L $102A,A0 ; Restore A0 from Memory
    MOVEM.L D0/D6/A0-A2,-(A7) ; Save Registers to Stack
    
* Get START Address in A1
    LEA DATA1,A0 ; Set Pointer to First Data Save Location
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BF_INV ; If yes, then Command is Invalid
    MOVE.L (A0)+,A1 ; Get First Address in A1, and then Set Pointer to Second Data Save Location
    
* Check if START Address is Even
    MOVE.L A1,D0 ; Get Address in D0
    BTST #0,D0 ; Check if D0 is even
    BNE BF_INV ; If no, then Address is Invalid

* Get END Address in A2
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BF_INV ; If yes, then Command is Invalid
    MOVE.L (A0)+,A2 ; Get Second Address in A2, and then Set Pointer to Third Data Save Location
    
* Check if END Address is Even
    MOVE.L A2,D0 ; Get Address in D0
    BTST #0,D0 ; Check if D0 is even
    BNE BF_INV ; If no, then Address is Invalid
    
* Get Data in D0
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BF_INV ; If yes, then Command is Invalid
    MOVE.L (A0),D0 ; Get Data in D0
    
* Check if Data is Word Size
    CMP.L #$FFFF,D0 ; Check id D0 > Largest Word
    BGT BF_INV ; If yes, then Data is not Word Size
    
    JSR CHK_END ; Check if reached end of input. If not, then Command Invalid
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BF_INV ; If yes, then Command is Invalid

BF_LOOP CMP.L A1,A2 ; Check if A2 <= A1
    BLE BF_END ; If yes, then Block Fill Complete
    
    MOVE.W D0,(A1)+ ; Fill Word in the Block
    BRA BF_LOOP ; Loop While in Address Range

BF_END MOVEM.L (A7)+,D0/D6/A0-A2 ; Restore Registers from Stack
    RTS ; Return from Subroutine 
    
BF_INV JSR INVALID ; Display Error Message
    MOVEM.L (A7)+,D0/D6/A0-A2 ; Restore Registers from Stack
    RTS ; Return from Subroutine 
*-----------------------------------------------------------------------------------------------------------
BMOV
* Copy a Block of Memory from One Place to Another
* Inputs: Start & End Address of Source, Start Address of Destination

    MOVE.L $102A,A0 ; Restore A0 from Memory
    MOVEM.L D6/A0-A3,-(A7) ; Save Registers to Stack 
    
* Get START Address in A1
    LEA DATA1,A0 ; Set Pointer to First Data Save Location
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BMOV_INV ; If yes, then Command is Invalid
    MOVE.L (A0)+,A1 ; Get First Address in A1, and then Set Pointer to Second Data Save Location

* Get END Address in A2
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BMOV_INV ; If yes, then Command is Invalid
    MOVE.L (A0)+,A2 ; Get Second Address in A2, and then Set Pointer to Third Data Save Location
    
* Get START Address #2 in A3
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BMOV_INV ; If yes, then Command is Invalid
    MOVE.L (A0),A3 ; Get Second Address in A2
    
    JSR CHK_END ; Check if reached end of input. If not, then Command Invalid
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BMOV_INV ; If yes, then Command is Invalid

BMOV_LOOP CMP.L A1,A2 ; Check if A2 <= A1
    BLE BMOV_END ; If yes, then Block Move Complete
    
    MOVE.B (A1)+,(A3)+ ; Move Byte from Block
    BRA BMOV_LOOP ; Loop While in Address Range

BMOV_END MOVEM.L (A7)+,D6/A0-A3 ; Restore Registers from Stack
    RTS ; Return from Subroutine
    
BMOV_INV JSR INVALID ; Display Error Message
    MOVEM.L (A7)+,D6/A0-A3 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
BTST
* Desctructive Test for a Memory Block
* Data is Alternatively Read & Written to Ensure that the Memory Location can Maintain Data

    MOVE.L $102A,A0 ; Restore A0 from Memory
    MOVEM.L D0-D5/A0-A3,-(A7) ; Save Registers to Stack
    
* Get START Address in A1
    LEA DATA1,A0 ; Set Pointer to First Data Save Location
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BTST_INV ; If yes, then Command is Invalid
    MOVE.L (A0)+,A1 ; Get First Address in A1, and then Set Pointer to Second Data Save Location

* Get END Address in A2
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BTST_INV ; If yes, then Command is Invalid
    MOVE.L (A0)+,A2 ; Get Second Address in A2, and then Set Pointer to Third Data Save Location
    
    JSR CHK_END ; Check if reached end of input. If not, then Command Invalid
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BTST_INV ; If yes, then Command is Invalid

    MOVE.L A1,A0 ; Make Copy of START Address in A0
    MOVE.L A0,A3 ; Make Copy of START Address in A3

    MOVE.B #$AA,D4 ; Data to be written
    
* Write Data to Block
BTST_LOOP1 CMP.L A1,A2 ; Check if A2 <= A1
    BLE BTST_NEXT1 ; If yes, then Block Write Complete
    
    MOVE.B D4,(A1)+ ; Write Byte to Block
    BRA BTST_LOOP1 ; Loop While in Address Range
    
BTST_NEXT1  ;MOVE.B #$3C,(A0) ; Create a Block Test Error at Starting Address

* Read Data from Block
BTST_LOOP2 CMP.L A0,A2 ; Check if A2 <= A0
    BLE BTST_PASS ; If yes, then Block Read Complete
    
    MOVE.B (A0)+,D5 ; Read Byte from Block into Temporary Register
    CMP.B D4,D5 ; Check if Read Value = Written Value
    BNE BTST_FAIL ; If no, then Block Test Failed
    BRA BTST_LOOP2 ; Loop While in Address Range
    
BTST_PASS MOVE.L A3,A0 ; Restore START Address in A0
    MOVE.L A3,A1 ; Restore START Address in A1
    
    CMP.B #$55,D4 ; Check if D4 = $55
    BEQ BTST_SUCCESS ; Passed both Block Tests
    
    MOVE.B #$55,D4 ; New Data to be Written
    BRA BTST_LOOP1 ; Perform Operation Twice
    
* Display Block Test Passed Message
BTST_SUCCESS LEA BPASS,A1
    MOVE.B #13,D0 ; Set TRAP Funtion to Output String Starting at A1 with CR
    TRAP #15
    BRA BTST_END ; End of Block Test
    
* Display Block Test Failed Message
BTST_FAIL LEA BFAIL,A1
    MOVE.B #13,D0 ; Set TRAP Funtion to Output String Starting at A1 with CR
    TRAP #15
    
* Display Failure Address
    MOVE.L A0,D2 ; Get Address of Latter Byte
    SUB.L #1,D2 ; Get Address of Failed Byte
    MOVE.B #2,D3 ; Set Number of Bytes to Display = 2
    JSR DISPREG ; Display Failure Address
    
    JSR SPACE ; Leave a Blank Space
    
* Display Written Byte
    MOVE.B #1,D3 ; Set Number of Bytes to Display = 1
    MOVE.L D4,D2 ; Data to be Written
    JSR DISPREG ; Display Written Byte
    
    JSR SPACE ; Leave a Blank Space
    
* Display Read Byte
    MOVE.L D5,D2 ; Data to be Written
    JSR DISPREG ; Display Read Byte
    
    JSR NEWLINE ; Print a Blank Line
    
BTST_END MOVEM.L (A7)+,D0-D5/A0-A3 ; Restore Registers from Stack
    RTS ; Return from Subroutine
    
BTST_INV JSR INVALID ; Display Error Message
    MOVEM.L (A7)+,D0-D5/A0-A3 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
BSCH
* Searches for a String in Memory
* Returns all matches

    MOVE.L $102A,A0 ; Restore A0 from Memory
    MOVEM.L D0-D4/A0-A5,-(A7) ; Save Registers to Stack
    
* Get START Address in A1
    LEA DATA1,A0 ; Set Pointer to First Data Save Location
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BSCH_INV ; If yes, then Command is Invalid
    MOVE.L (A0)+,A1 ; Get First Address in A1, and then Set Pointer to Second Data Save Location
    
* Get END Address in A2
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BSCH_INV ; If yes, then Command is Invalid
    MOVE.L (A0)+,A2 ; Get Second Address in A2, and then Set Pointer to Third Data Save Location

* Look for Space Character followed by a Double Quote
    LEA INP_PTR,A5 ; Get Address of Input Pointer Location in A5
    MOVE.L (A5),A4 ; Get Current Location of Input Pointer in A4
    
    CMP.B #$20,(A4)+ ; Check if Next Character is a Space
    BNE BSCH_INV ; If no, then Command is Invalid
    
    CMP.B #$22,(A4)+ ; Check if Next Character is a Double Quote
    BNE BSCH_INV ; If no, then Command is Invalid
    
    MOVE.L A4,A3 ; Store Starting Address of String Input in A3
    
* Check if String Ends with Double Quote and has at least one character
    CMP.B #$22,(A4)+ ; Check if Next Character is a Double Quote
    BEQ BSCH_INV ; If yes, Command is Invalid Since String Cannot Be Empty
    SUB.L #1,A4 ; If no, Go Back to Previous Character

BSTR_LOOP CMP.B #$22,(A4)+ ; Check if Next Character is a Double Quote
    BEQ BSTR_END ; If yes, then Reached End of String
    
    CMP.B #0,-(A4) ; Check if Character is null
    BEQ BSCH_INV ; If yes, then Command is Invalid
    ADD.L #1,A4 ; Go to Next Character
    BRA BSTR_LOOP ; If no, then Keep Looping 
    
BSTR_END MOVE.L A4,(A5) ; Store Current Location of Input Pointer in INP_PTR

    JSR CHK_END ; Check if reached end of input. If not, then Command Invalid
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BSCH_INV ; If yes, then Command is Invalid
    
    CLR.L D4 ; Clear Flag to Check if String is Found
    
BSCH_NO CMPA.L A1,A2 ; Check if A2 <= A1
     BLE BSCH_DONE ; If yes, Search Exhausted
     MOVE.L A3,A4  ; Make a copy of Start Address of Input String
     MOVE.L A1,A5  ; Save Start Address of Located String in A5
BSCH_YES  CMPA.L A1,A2 ; Check if A2 <= A1
     BLE BSCH_DONE ; If yes, Search Exhausted
     MOVE.B (A4)+,D1 ; Get character from Input String in D1
     CMP.B #$22,D1 ; Check if Character is a Double Quote
     BEQ BSCH_MATCH ; If yes, then Match Found
     MOVE.B (A1)+,D2 ; Get character to Compare with in D2
     CMP.B D1,D2 ; Check if Characters Match
     BNE BSCH_NO ; If no, Restart Search from Following Address
     BRA BSCH_YES ; Continue Searching
       
BSCH_MATCH MOVE.L #1,D4 ; Set Flag to Denote String Was Found
    MOVE.B #16,D2 ; Set Base for Output Operation to 16

* Display Address
    
    MOVE.L A5,D2 ; Get START Address in D2
    MOVE.B #2,D3 ; Set Number of Bytes to Display = 2
    JSR DISPREG ; Display Address
    
    JSR SPACE ; Leave a Blank Space
   
* Display String
    JSR QUOTE ; Display Double Quote
    
    MOVE.B #6,D0 ; Set TRAP Function to Output Character in D1.B

BSD_LOOP CMP.L A5,A1 ; Check if A1 <= A5
    BLE BSD_END ; If yes, then Memory Set Display Complete
    
    MOVE.B (A5)+,D1 ; Get Character in D1
    TRAP #15
    BRA BSD_LOOP ; Loop till End of String
    
BSD_END JSR QUOTE ; Display Double Quote

    JSR SPACE ; Leave Blank Space
    
    MOVE.L A1,A5 ; Save Value of A1 in A5
    
* Display Success Message
    LEA SFOUND,A1
    MOVE.B #13,D0
    TRAP #15
    MOVE.L A5,A1 ; Restore Value of A1
    
    BRA BSCH_NO ; Look for More Matches

BSCH_DONE CMP.L #1,D4 ; Check Flag to See if String Was Found
    BEQ BSCH_END ; If yes, then Block Search Complete
    
* Display Failure Message Since String Was Not Found
    LEA SLOST,A1
    MOVE.B #13,D0
    TRAP #15
    
BSCH_END MOVEM.L (A7)+,D0-D4/A0-A5 ; Restore Registers from Stack
    RTS ; Return from Subroutine
    
BSCH_INV JSR INVALID ; Display Error Message
    MOVEM.L (A7)+,D0-D4/A0-A5 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*----------------------------------------------------------------------------------------------------------- 
GO
* Executes Code in Memory Starting at the Inputted Address
*
    MOVE.L $102A,A0 ; Restore A0 from Memory
    MOVEM.L D6/A0/A6,-(A7) ; Save Registers to Stack
    
* Get Address in A6
    LEA DATA1,A0
    JSR GET_DATA
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ NO_GO ; If yes, then Command is Invalid
    MOVE.L (A0),A6
    
    JSR CHK_END ; Check if reached end of input. If not, then Command Invalid
    CMP.L #1,D6 ; Check if D6 = 1
    BEQ NO_GO ; If yes, then Command is Invalid
   
    MOVEM.L (A7)+,D6/A0 ; Restore Registers from Stack
    ADD.L #8,A7 ; Throw Two Long Words from Stack
 
* Jump to Adress
    JMP (A6) 
    
NO_GO JSR INVALID ; Display Error Message
    MOVEM.L (A7)+,D6/A0/A6 ; Restore Registers from Stack 
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
DF 
* Displays Current Values PC, SR, US, SS, Data Registers and Address Registers
*
    MOVE.L $102A,A0 ; Restore A0 from Memory
    
    MOVE.L D6,-(A7) ; Save D6 on Stack
    
    JSR CHK_END ; Check if reached end of input. If not, then Command Invalid
    CMP.L #1,D6 ; Check if D6 = 0
    BEQ NO_DF ; If yes, then command is invalid
    
    MOVE.L (A7)+,D6 ; Restore D6 from Stack
    MOVE.L A0,-(A7) ; Save A0 on the Stack
    
* Save Value of PC in memory (REG_X)
    LEA REG_X,A0 ; Get Address of REG_X in A0
    ADD.L #4,A7 ; Get to PC Location
    MOVE.L (A7),(A0) ; Save Value
    SUB.L #4,A7 ; Return to Otiginal Location
    
* Save Value of SS (equal to A7) in memory
    LEA REG_Y,A0 ; Get Address of REG_Y in A0
    MOVE.L A7,(A0) ; Save SS/A7 in REG_Y (Memory)
    ADD.L #8,(A0) ; Get Actual Value of SS/A7 in REG_X
    
    MOVE.L (A7)+,A0 ; Restore A0 from the Stack
    
    MOVEM.L D0-D7/A0-A6,-(A7) ; Store All Registers on Stack
    MOVEM.L D0-D7/A0-A6,-(A7) ; Store Another Copy of All Registers on Stack
    
* Display PC
    MOVE.B #$50,D1 ; Output Character 'P' 
    MOVE.B #6,D0
    TRAP #15
    
    MOVE.B #$43,D1 ; Output Character 'C' 
    TRAP #15
    
    MOVE.B #$3D,D1 ; Output Character '=' 
    TRAP #15
    
    LEA REG_X,A0 ; Get Address of REG_X in A0
    MOVE.L (A0),D2 ; Get PC in D2
    MOVE.L #4,D3 ; Set Number of Bytes to Display = 4
    JSR DISPREG
    
    JSR SPACE ; Leave a Blank Space
    
* Display SR
    MOVE.B #$53,D1 ; Output Character 'S' 
    MOVE.B #6,D0
    TRAP #15
    
    MOVE.B #$52,D1 ; Output Character 'R' 
    TRAP #15
    
    MOVE.B #$3D,D1 ; Output Character '=' 
    TRAP #15

    MOVE SR,D2 ; Get SR in D2
    MOVE.B #2,D3 ; Set Number of Bytes to Display = 2
    JSR DISPREG
    
    JSR SPACE ; Leave a Blank Space
     
* Display US
    MOVE.B #$55,D1 ; Output Character 'U' 
    MOVE.B #6,D0
    TRAP #15
    
    MOVE.B #$53,D1 ; Output Character 'S' 
    TRAP #15
    
    MOVE.B #$3D,D1 ; Output Character '=' 
    TRAP #15

    MOVE USP,A1 ; Get US in A1
    MOVE.L A1,D2 ; Get US in D2
    MOVE.L #4,D3 ; Set Number of Bytes to Display = 4
    JSR DISPREG
    
    JSR SPACE ; Leave a Blank Space
    
* Display SS
    MOVE.B #$53,D1 ; Output Character 'S' 
    MOVE.B #6,D0
    TRAP #15
    
    MOVE.B #$53,D1 ; Output Character 'S' 
    TRAP #15
    
    MOVE.B #$3D,D1 ; Output Character '=' 
    TRAP #15

    LEA REG_Y,A0 ; Get Address of REG_Y in A0
    MOVE.L (A0),D2 ; Get SS from Memory
    JSR DISPREG
    
    JSR NEWLINE ; Go to Next Line

DISP_DA
    
    MOVE.B #0,D5 ; Counter: 0 = D, 1 = A, >1 = Operation Complete
    MOVE.B #6,D0 ; Output Character in D1.B
    MOVE.L #4,D3 ; Set Number of Bytes to Display = 4

DA_START 
    MOVE.B #$30,D4 ; Counter for Register Number    
    
RLOOP CMP.B #1,D5 ; Check if Couter is 1
    BEQ A_REG ; If yes, then Register to be Displayed is an Adress Register
    
    MOVE.B #$44,D1 ; Output Character 'D' 
    BRA D_REG ; Register to be Displayed is a Data Register
    
A_REG MOVE.B #$41,D1 ; Output Character 'A'

D_REG TRAP #15

    MOVE.B D4,D1 ; Output Register Number 
    TRAP #15
    
    MOVE.B #$3D,D1 ; Output Character '=' 
    TRAP #15
    
    TST.B D5 ; Check if Data Registers are Being Displayed
    BEQ CONTINUE ; If yes, then Continue
    
    CMP.B #$37,D4 ; Check if A7 is to be Displayed
    BEQ DF_DONE ; If yes, then Exit Display Registers Loop
    
CONTINUE MOVE.L (A7)+,D2 ; Get Register Value from Stack
    JSR DISPREG
    
    JSR SPACE ; Leave a Blank Space
    
    ADD.B #1,D4 ; Increment Register Number
    
    CMP.B #$34,D4 ; Check if Register Number < 4
    BLT RLOOP ; Loop for Registers D0-D3 & A0-A3
    
    CMP.B #$34,D4 ; Check if Register Number != 4
    BNE SAME_LINE ; If no, then Display Next Register on the Same Line
    JSR NEWLINE ; If yes, then Display Next Register on the Next Line
    
SAME_LINE CMP.B #$38,D4 ; Check if Register Number < 8
    BLT RLOOP ; Loop for Registers D4-D7
 
    ADD.B #1,D5 ; Increment Counter
    JSR NEWLINE ; Go to Next Line
    BRA DA_START ; Continue Displaying Registers till A7
    
DF_DONE MOVE.L (A0),D2 ; Get A7 from Memory
    JSR DISPREG ; Display A7
    
    JSR NEWLINE ; Leave a Blank Line
    
    MOVEM.L (A7)+,D0-D7/A0-A6 ; Restore All Registers from Stack
    RTS ; Return from Subroutine
    
NO_DF JSR INVALID ; Display Error Message
    MOVE.L (A7)+,D6 ; Restore D6 from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------    
EXIT
* Exits the Monitor Program
*
    MOVE.L $102A,A0 ; Restore A0 from Memory
    MOVE.L D6,-(A7) ; Save Register to Stack
    
    JSR CHK_END ; Check if reached end of input. If not, then Command Invalid
    CMP.L #1,D6 ; Check if D6 = 0
    BEQ NO_EXIT ; If yes, then Command Invalid
    
    JSR NEWLINE ; Display Blank Line

    JSR THANKYOU ; Display Thank You Message
    
* Exit Monitor Program
    MOVE.B #9,D0 ; Set TRAP Function to HALT Simulator
    TRAP #15
    
NO_EXIT JSR INVALID ; Display Error Message
    MOVE.L (A7)+,D6 ; Restore Register from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
BREV 
* Reverse the order of Bytes in a Block of Data between 2 Inputted Addresses
* (Can be used to reverse strings)

    MOVE.L $102A,A0 ; Restore A0 from Memory
    MOVEM.L D5-D6/A0-A2,-(A7) ; Save Registers to Stack

* Get START Address in A1
    LEA DATA1,A0 ; Set Pointer to First Data Save Location
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BREV_INV ; If yes, then Command is Invalid
    MOVE.L (A0)+,A1 ; Get First Address in A1, and then Set Pointer to Second Data Save Location
    
* Get END Address in A2
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BREV_INV ; If yes, then Command is Invalid
    MOVE.L (A0),A2 ; Get Second Address in A2
    
    JSR CHK_END ; Check if Command is null terminated
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ BREV_INV ; If yes, then Command is Invalid
    
BREV_LOOP CMP.L A1,A2 ; Check if A2 <= A1
    BLE BREV_DONE ; If yes, then Subroutine Complete
    
* Swap First and Last Byte
    MOVE.B (A1),D5 ; Move First Byte to Temporary Regiter
    MOVE.B -(A2),(A1)+ ; Move Last Byte in First Address, then Increment Start Address
    MOVE.B D5,(A2) ; Move First Byte from Temporary Register to Last Address
    
    BRA BREV_LOOP ; Loop till Entire Block is Reversed
    
BREV_DONE MOVEM.L (A7)+,D5-D6/A0-A2 ; Restore Registers from Stack
    RTS ; Return from Subroutine
    
BREV_INV JSR INVALID ; Display Error Message
     MOVEM.L (A7)+,D5-D6/A0-A2 ; Restore Registers from Stack
    RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
UPPER
* Convert Null Terminated String Starting At Inputted Address to Uppercase Letters
*
    MOVE.L $102A,A0 ; Restore A0 from Memory
    MOVEM.L D6/A0-A1,-(A7) ; Save Registers to Stack

* Get START Address in A1
    LEA DATA1,A0 ; Set Pointer to First Data Save Location
    JSR GET_DATA ; Get Data from Input
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ UPPER_INV ; If yes, then Command is Invalid
    MOVE.L (A0),A1 ; Get First Address in A1
    
    JSR CHK_END ; Check if Command is null terminated
    CMP.B #1,D6 ; Check if D6 = 1
    BEQ UPPER_INV ; If yes, then Command is Invalid
    
UPPER_LOOP CMP.B #0,(A1) ; Check if Character is null
    BLT UPPER_END ; If yes, then operation complete  
    
    CMP.B #$61,(A1) ; Check if (A1) < $61 (Character 'a')
    BLT NO_ALF ; If yes, then character is not a lowercase alphabet
    
    CMP.B #$7A,(A1) ; Check if (A1) > $7A (Character 'z')
    BGT NO_ALF ; If yes, then character is not a lowercase alphabet
    
    SUB.B #$20,(A1) ; Convert alphabet to uppercase
    
NO_ALF ADD.L #1,A1 ; Go to next character
    BRA UPPER_LOOP ; Loop till null character

UPPER_END MOVEM.L (A7)+,D6/A0-A1 ; Restore Registers from Stack
    RTS ; Return from subroutine  
    
UPPER_INV JSR INVALID ; Display Error Message
    MOVEM.L (A7)+,D6/A0-A1 ; Restore Registers from Stack
    RTS ; Return from subroutine  
*-----------------------------------------------------------------------------------------------------------
DISPREG 
* Displays Value in D2, Size (Number of Bytes in D3)
*
      MOVEM.L D0-D5/A0,-(A7) ; Save Registers to Stack
      
      LEA REG_X,A0 ; Get Start Address of Register X Space
      MOVE.L D2,(A0) ; Store Data to be Displayed in Register X Space
      
      MOVE.L #4,D5 ; Offset for Start Address of Bytes to be Displayed = 4-Size
      SUB.B D3,D5 ; Offset = 4-Size
      
      ADD.L D5,A0 ; Add Offset to Start Address
      
      MOVE.B #6,D0 ; Set TRAP Function Number to Output Character in D1.B 
      
NBYTES MOVE.B (A0)+,D1 ; Get Byte in D1
      MOVE.B D1,D4 ; Make Copy of Byte in D4
      LSR.B #4,D1 ; Get Upper Half Byte in D1
      AND.B #$0F,D4 ; Get Lower Half Byte in D4
      
      MOVE.B #2,D5 ; Counter for Number of Half Bytes per Byte
      
TWICE CMP.B #9,D1 ; Check if D1 > 9
      BGT ALPHA ; If yes, then Half Byte is A-F
      ADD.B #$30,D1 ; If no, then Add #$30 to Half-Byte to Convert into ASCII
      BRA NEXT ; Go to Next Step
ALPHA ADD.B #$37,D1 ; Add #$37 to Half Byte to Convert into ASCII
NEXT  TRAP #15 ; Display Half Byte

      MOVE.B D4,D1 ; Get Lower Half Byte in D1
      SUB.B #1,D5 ; Decrement Counter
      BNE TWICE ; Perform Operation Twice
      
      SUB.B #1,D3 ; Decrement Counter
      BNE NBYTES ; Perform Operation for N Bytes
      
      MOVEM.L (A7)+,D0-D5/A0 ; Restore Registers from Stack
      RTS ; Return from Subroutine
*-----------------------------------------------------------------------------------------------------------
REVERSE
* Reverses Data in Memory (Word Size Operation)
*
    MOVEM.L D0/A0-A2,-(A7) ; Save Registers to Stack
    
    LEA DATA1,A0 ; Set Pointer to Start Address of Data 1
    MOVE.L (A0)+,A1 ; Get Data 1 in A1
    MOVE.L (A0)+,A2 ; Get Data 2 in A2
    
LOOP CMP.L A1,A2 ; Ckeck if A2 <= A1
    BLE REVERSE_END ; If yes, then Reversal Complete
    
    MOVE.W (A1),D0 ; Move Word from Start of List to Temporary Register
    MOVE.W -(A2),(A1)+ ; Move Word from End of List to Start of List and then Shrink List
    MOVE.W D0,(A2) ; Move Word from Temporary Register to End of List
    BRA LOOP ; Loop while in Address Range
    
REVERSE_END MOVEM.L (A7)+,D0/A0-A2 ; Restore Registers from Stack
    RTS ; Return from subroutine  
*----------------------------------------------------------------------------------------------------------- 
*-----------------------------------------------------------------------------------------------------------    
    

    
***************************
***   EXCEPTION SPACE   ***
***************************
*-----------------------------------------------------------------------------------------------------------
*-------------------------------------------- DATA SPACE ---------------------------------------------------

* Error Messages for Exceptions
SBERR  DC.B 'BUS ERROR OCCURRED!'
       DC.B 0

SADR   DC.B 'ADDRESS ERROR OCCURRED!'
       DC.B 0
     
SILL   DC.B 'ILLEGAL INSTRUCTION ERROR OCCURRED!'
       DC.B 0

SPRIV  DC.B 'PRIVILEGE VIOLATION ERROR OCCURRED!'
       DC.B 0
     
SZERO  DC.B 'DIV ZERO ERROR OCCURRED!'
       DC.B 0

SCHK   DC.B 'CHK INSTRUCTION ERROR OCCURRED!'
       DC.B 0
     
SLINEA DC.B 'LINE A EMULATOR ERROR OCCURRED!'
       DC.B 0

SLINEF DC.B 'LINE F EMULATOR ERROR OCCURRED!'
       DC.B 0
       DC.B 0
       
*-----------------------------------------------------------------------------------------------------------
*-------------------------------------------- PROGRAM SPACE ------------------------------------------------
BUS_ERR 
    LEA SBERR,A1 ; Load Error Message
    BRA BUS_ADR ; Execute Code Common to  Bus & Address Errors
ADRS_ERR
    LEA SADR,A1 ; Load Error Message
*-----------------------------------------------------------------------------------------------------------    
* Code Common to  Bus & Address Errors
BUS_ADR JSR NEWLINE ; Go to Next Line
    
    MOVE.B #13,D0
    TRAP #15 
    
    MOVE.W (A7)+,D0 ; Throw First Word from Stack
    
    MOVE.L (A7)+,D0 ; Get Bus Address in D0
    MOVE.W (A7)+,D1 ; Get Instruction Register in D1
    
    MOVE.W (A7)+,D2 ; Get Supervisor Status Word in D2
    MOVE.B #2,D3 ; Set Number of Bytes to Display = 2
    JSR DISPREG ; Display SSW
    
    JSR SPACE ; Leave Blank Space
    
    MOVE.l D0,D2 ; Get Bus Address in D2
    MOVE.B #4,D3 ; Set Number of Bytes to Display = 4
    JSR DISPREG ; Display BA
    
    JSR SPACE ; Leave Blank Space
    
    MOVE.l D1,D2 ; Get Instruction Register in D2
    MOVE.B #2,D3 ; Set Number of Bytes to Display = 2
    JSR DISPREG ; Display IR
    
    JSR NEWLINE ; Go to Next Line
    
    MOVE.L (A7)+,D5 ; Throw Long Word from Stack

ERR_DF ; Short Hand Way to Display Data & Address Register Values Using the DF Command

    MOVEM.L A0,-(A7) ; Save A0 on Stack
    
    LEA DATA3,A0 ; Load Address of DATA3 in A0
    MOVE.L A7,(A0) ; Store Value of A7 in DATA3
    ADD.L #4,(A0) ; Get Value of Stack at the Time of Exception
    
    ADD.L #8,A7 ; Move 2 Long Words Down the Stack
    PEA *+22 ; Effective Address to Return from RTS
    SUB.L #4,A7 ; Move 1 Long Word Up the Stack
    
    MOVEM.L (A7)+,A0 ; Restore A0 from Stack
    
    MOVEM.L D0-D7/A0-A6,-(A7) ; Store All Registers on Stack
    MOVEM.L D0-D7/A0-A6,-(A7) ; Store Another Copy of All Registers on Stack
    
    BRA DISP_DA ; Call Part of the DF Command 

    ADD.L #2,A7 ; Throw Long Word from Stack  
    
    BRA RUN_MONITOR ; Return to Terminal
*-----------------------------------------------------------------------------------------------------------       
ILL_INST
    LEA SILL,A1 ; Load Error Message
    BRA O_ERRS ; Execute Code Common to All Exceptions Except Bus & Address Errors

DIV_ZERO
    LEA SZERO,A1 ; Load Error Message
    BRA O_ERRS ; Execute Code Common to All Exceptions Except Bus & Address Errors

CHK_INST
    LEA SCHK,A1 ; Load Error Message
    BRA O_ERRS ; Execute Code Common to All Exceptions Except Bus & Address Errors
    
PRIV_VIOL
    LEA SPRIV,A1 ; Load Error Message
    BRA O_ERRS ; Execute Code Common to All Exceptions Except Bus & Address Errors

LINE_A
    LEA SLINEA,A1 ; Load Error Message
    BRA O_ERRS ; Execute Code Common to All Exceptions Except Bus & Address Errors

LINE_F
    LEA SLINEF,A1 ; Load Error Message
    BRA O_ERRS ; Execute Code Common to All Exceptions Except Bus & Address Errors
*-----------------------------------------------------------------------------------------------------------  
* Code Common to All Exceptions Except Bus & Address Errors  
O_ERRS  JSR NEWLINE ; Go to Next Line
    MOVE.B #13,D0 ; Display String at A1
    TRAP #15 
    
    BRA ERR_DF ; Display Data & Address Registers
*-----------------------------------------------------------------------------------------------------------
*----------------------------------------------------------------------------------------------------------- 
   
*-----------------------------------------------------------------------------------------------------------
*-------------------------------------  END OF MONITOR PROGRAM ---------------------------------------------
*-----------------------------------------------------------------------------------------------------------




*-----------------------------------------------------------------------------------------------------------
*------------------------------------- CODE TO TEST OUT EXCEPTIONS -----------------------------------------
*-----------------------------------------------------------------------------------------------------------

* ADDRESS ERROR
    ORG $4100
ERR_ADR MOVE.L $5001,D0 ; Trying to Access Long Word at Odd Address

* BUS ERROR
    ORG $4200
ERR_BUS MOVE.B $FFFFF,D0 ; Trying to Access Invalid Address

* ILLEGAL INSTRUCTION ERROR
    ORG $4300
ERR_ILL ILLEGAL ; Illegal Instruction

* PRIVILEGE VIOLATION ERROR
    ORG $4400
ERR_PRIV MOVE #0,SR ; Go to User Mode
    MOVE USP,A1 ; Try to Use Priviledged Instruction

* DIVIDE BY ZERO ERROR
    ORG $4500
ERR_DIV  DIVU #0,D4 ; Trying to Divide a Number by Zero

* CHK INSTRUCTION ERROR
    ORG $4600
ERR_CHK MOVE.B #5,D0 ; Store a Value in D0
        CHK #1,D0 ; CHK: 0 < D0 < 1
        
* LINE A EMULATOR ERROR
    ORG $4700
ERR_LINEA ; Store $A000 here using MM Command

* LINE F EMULATOR ERROR
    ORG $4800
ERR_LINEF ; Store $F000 here using MM Command

*-----------------------------------------------------------------------------------------------------------
*--------------------------------------------------- END OF CODE -------------------------------------------
*-----------------------------------------------------------------------------------------------------------


    END    START        ; last line of source
    
    
    


















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
