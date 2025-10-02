;Student IDs: 210021120 and 210021160  


; Student Data Table Management System
; Intel 8086 Assembly for emu8086


.MODEL SMALL
.STACK 100H

.DATA
    ; Constants
    MAX_ROWS EQU 50    ;For the max no. of rows
    MAX_COLS EQU 10    ;For the max no. of columns
    MAX_STR_LEN EQU 8
    
    ; Messages shown for taking the input
    msg_welcome DB 'Student Data Table Management System', 0DH, 0AH, '$'
    msg_col_count DB 0DH, 0AH, 'Enter number of columns (1-10): $'
    msg_row_count DB 0DH, 0AH, 'Enter number of rows (1-50): $'
    msg_col_name DB 0DH, 0AH, 'Enter name for column $'
    msg_col_type DB ': Is this column numeric? (Y/N): $'
    msg_enter_data DB 0DH, 0AH, 'Enter data for row $'
    msg_col DB ', column $'
    msg_display DB 0DH, 0AH, 'Current Table:', 0DH, 0AH, '$'
    msg_sort_prompt DB 0DH, 0AH, 'Enter column number to sort by (1-', '$'
    msg_invalid DB 0DH, 0AH, 'Invalid input! Try again.', 0DH, 0AH, '$'
    msg_sorted DB 0DH, 0AH, 'Table sorted successfully!', 0DH, 0AH, '$'
    separator DB ' | ', '$'
    newline DB 0DH, 0AH, '$'
    colon_space DB ': $'
    
    ; Data structures
    col_names DB MAX_COLS * (MAX_STR_LEN + 1) DUP('$') ; Column names
    col_types DB MAX_COLS DUP(0) ; 0=string, 1=numeric
    table_data DB MAX_ROWS * MAX_COLS * (MAX_STR_LEN + 1) DUP('$') ; Table data
    
    ; Variables
    num_cols DB 0
    num_rows DB 0
    sort_col DB 0
    temp_buffer DB MAX_STR_LEN + 2, ?, MAX_STR_LEN + 1 DUP('$')
    current_row DB 0
    current_col DB 0
    i DB 0
    j DB 0

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
    ; Display welcome message
    LEA DX, msg_welcome
    MOV AH, 09H
    INT 21H
    
    ; Get number of columns
    CALL GET_COLUMN_COUNT
    
    ; Get column names and types
    CALL GET_COLUMN_DETAILS
    
    ; Get number of rows
    CALL GET_ROW_COUNT
    
    ; Get table data
    CALL GET_TABLE_DATA
    
    ; Display the table
    CALL DISPLAY_TABLE
    
    ; Sort the table
    CALL SORT_TABLE
    
    ; Display sorted table
    LEA DX, msg_sorted
    MOV AH, 09H
    INT 21H
    CALL DISPLAY_TABLE
    
    ; Exit program
    MOV AH, 4CH
    INT 21H
MAIN ENDP


; Subroutine to get number of columns (supports 1-10)

GET_COLUMN_COUNT PROC
    CC_LOOP:
        LEA DX, msg_col_count
        MOV AH, 09H
        INT 21H
        
        ; Read first digit
        MOV AH, 01H
        INT 21H
        
        ; Check if '1' (possible two-digit is '10')
        CMP AL, '1'
        JE CHECK_FOR_10
        
        ; Check single digits 2-9
        CMP AL, '2'
        JB INVALID_CC
        CMP AL, '9'
        JA INVALID_CC
        
        ; Valid single digit
        SUB AL, '0'
        MOV num_cols, AL
        RET
        
    CHECK_FOR_10:
        ; Read next character
        MOV AH, 01H
        INT 21H
        CMP AL, '0'
        JE VALID_10
        CMP AL, 0DH  ; If Enter pressed after '1'
        JE VALID_1
        JMP INVALID_CC
        
    VALID_10:                  ; Label for case when column count is 10
    MOV num_cols, 10       ; Store 10 into num_cols variable
    RET                    ; Return from procedure

   VALID_1:                   ; Label for case when column count is 1
    MOV num_cols, 1        ; Store 1 into num_cols variable
    RET                    ; Return from procedure

   INVALID_CC:                ; Label for invalid column count input
    LEA DX, msg_invalid    ; Load address of "invalid input" message into DX
    MOV AH, 09H            ; DOS function 09h: print string
    INT 21H                ; Call DOS interrupt to display the message
    JMP CC_LOOP            ; Jump back to input loop for column count

GET_COLUMN_COUNT ENDP      ; End of GET_COLUMN_COUNT procedure






; Subroutine to get column names and types


GET_COLUMN_DETAILS PROC    ; Start of GET_COLUMN_DETAILS procedure
    MOV CL, num_cols       ; Load number of columns into CL (loop counter low byte)
    MOV CH, 0              ; Clear CH to make CX = number of columns
    MOV current_col, 1     ; Set current column number to 1 (for user display)

GCD_LOOP:                  ; Label for loop through each column
    PUSH CX                ; Save CX on stack (preserve column loop counter for later use)

        ; Display column prompt
        LEA DX, msg_col_name
        MOV AH, 09H
        INT 21H
        
        ; Display column number
        MOV DL, current_col
        ADD DL, '0'
        MOV AH, 02H
        INT 21H
        
        LEA DX, colon_space
        MOV AH, 09H
        INT 21H
        
        ; Get column name using buffered input
        LEA DX, temp_buffer
        MOV AH, 0AH
        INT 21H
        
        ; Calculate position in col_names array
        MOV AL, current_col
        DEC AL
        MOV BL, MAX_STR_LEN + 1
        MUL BL
        MOV SI, AX  ; SI = offset in col_names
        
        ; Copy name from temp_buffer to col_names
        MOV BX, 0
        MOV CL, temp_buffer[1]  ; Get actual length entered
        MOV CH, 0
        
        COPY_NAME:
            CMP BX, CX
            JAE END_COPY_NAME
            MOV AL, temp_buffer[BX+2] ; Skip length bytes
            MOV col_names[SI], AL
            INC SI
            INC BX
            JMP COPY_NAME
            
        END_COPY_NAME:
            MOV col_names[SI], '$' ; Null terminate
        
        ; Get column type
        LEA DX, msg_col_type
        MOV AH, 09H
        INT 21H
        
        MOV AH, 01H
        INT 21H
        
        ; Calculate position in col_types
        MOV BL, current_col
        DEC BL
        MOV BH, 0
        
        CMP AL, 'Y'
        JE NUMERIC_COL
        CMP AL, 'y'
        JE NUMERIC_COL
        MOV col_types[BX], 0 ; String
        JMP TYPE_DONE
        
        NUMERIC_COL:
            MOV col_types[BX], 1 ; Numeric
            
        TYPE_DONE:
            INC current_col
            POP CX
            LOOP GCD_LOOP
    RET
GET_COLUMN_DETAILS ENDP


; Subroutine to get number of rows

GET_ROW_COUNT PROC
    RC_LOOP:
        LEA DX, msg_row_count
        MOV AH, 09H
        INT 21H
        
        ; Read input
        MOV AH, 01H
        INT 21H
        
        ; Check for valid single digits 1-9
        CMP AL, '1'
        JB INVALID_RC
        CMP AL, '9'
        JA INVALID_RC
        
       SUB AL, '0'            ; Convert ASCII digit in AL to its numeric value (e.g., '5' ? 5)
    MOV num_rows, AL       ; Store the numeric value into num_rows variable
    RET                    ; Return from procedure

INVALID_RC:                ; Label for invalid row count input
    LEA DX, msg_invalid    ; Load address of "invalid input" message into DX
    MOV AH, 09H            ; DOS function 09h: print string
    INT 21H                ; Call DOS interrupt to display the message
    JMP RC_LOOP            ; Jump back to input loop for row count

GET_ROW_COUNT ENDP         ; End of GET_ROW_COUNT procedure



; Subroutine to get table data

GET_TABLE_DATA PROC
    MOV current_row, 1
    
    GTD_ROW_LOOP:
        MOV current_col, 1
        
        GTD_COL_LOOP:
            ; Display prompt
            LEA DX, msg_enter_data
            MOV AH, 09H
            INT 21H
            
            MOV DL, current_row
            ADD DL, '0'
            MOV AH, 02H
            INT 21H
            
            LEA DX, msg_col
            MOV AH, 09H
            INT 21H
            
            MOV DL, current_col
            ADD DL, '0'
            MOV AH, 02H
            INT 21H
            
            LEA DX, colon_space
            MOV AH, 09H
            INT 21H
            
            ; Calculate position in table_data
            MOV AL, current_row
            DEC AL
            MOV BL, num_cols
            MUL BL ; AL = (row-1)*num_cols
            MOV BL, MAX_STR_LEN+1
            MUL BL ; AX = (row-1)*num_cols*9
            
            MOV BX, AX ; BX = row offset
            
            MOV AL, current_col
            DEC AL
            MOV DL, MAX_STR_LEN+1
            MUL DL ; AX = (col-1)*9
            
            ADD BX, AX ; BX = full offset
            
            ; Get input
            LEA DX, temp_buffer
            MOV AH, 0AH
            INT 21H
            
            ; Copy to table
            MOV SI, 2 ; Skip length bytes
            MOV DI, BX
            MOV CL, temp_buffer[1]  ; Get actual length
            MOV CH, 0
            
            COPY_DATA:
                CMP CX, 0
                JE END_COPY_DATA
                MOV AL, temp_buffer[SI]
                MOV table_data[DI], AL
                INC SI
                INC DI
                DEC CX
                JMP COPY_DATA
                
            END_COPY_DATA:
                MOV table_data[DI], '$' ; Null terminate
            
            INC current_col
            MOV AL, current_col
            CMP AL, num_cols
            JBE GTD_COL_LOOP
        
        INC current_row
        MOV AL, current_row
        CMP AL, num_rows
        JBE GTD_ROW_LOOP
    RET
GET_TABLE_DATA ENDP


; Subroutine to display the table

DISPLAY_TABLE PROC
    ; Display header
    LEA DX, msg_display
    MOV AH, 09H
    INT 21H
    
    ; Display column headers
    MOV current_col, 0
    
    DISP_HEADER:
        ; Calculate position in col_names
        MOV AL, current_col
        MOV BL, MAX_STR_LEN+1
        MUL BL
        MOV SI, AX
        
        ; Display column name
        LEA DX, col_names[SI]
        MOV AH, 09H
        INT 21H
        
        INC current_col
        MOV AL, current_col
        CMP AL, num_cols
        JB HEADER_SEPARATOR
        JMP HEADER_DONE
        
        HEADER_SEPARATOR:
            LEA DX, separator
            MOV AH, 09H
            INT 21H
            JMP DISP_HEADER
    
    HEADER_DONE:
        ; New line after headers
        LEA DX, newline
        MOV AH, 09H
        INT 21H
    
    ; Display table data
    MOV current_row, 0
    
    DISP_ROW_LOOP:
        MOV current_col, 0
        
        DISP_COL_LOOP:
            ; Calculate position in table_data
            MOV AL, current_row
            MOV BL, num_cols
            MUL BL ; AL = row*num_cols
            MOV BL, MAX_STR_LEN+1
            MUL BL ; AX = row*num_cols*9
            
            MOV BX, AX ; BX = row offset
            
            MOV AL, current_col
            MOV DL, MAX_STR_LEN+1
            MUL DL ; AX = col*9
            
            ADD BX, AX ; BX = full offset
            
            ; Display data
            LEA DX, table_data[BX]
            MOV AH, 09H
            INT 21H
            
            INC current_col
            MOV AL, current_col
            CMP AL, num_cols
            JB COL_SEPARATOR
            JMP ROW_DONE
            
            COL_SEPARATOR:
                LEA DX, separator
                MOV AH, 09H
                INT 21H
                JMP DISP_COL_LOOP
        
        ROW_DONE:
            ; New line after each row
            LEA DX, newline
            MOV AH, 09H
            INT 21H
            
            INC current_row
            MOV AL, current_row
            CMP AL, num_rows
            JB DISP_ROW_LOOP
    
    RET
DISPLAY_TABLE ENDP


; Sort prompt procedure

SORT_PROMPT PROC
    SORT_PROMPT_LOOP:
        LEA DX, msg_sort_prompt
        MOV AH, 09H
        INT 21H
        
        MOV DL, num_cols
        ADD DL, '0'
        MOV AH, 02H
        INT 21H
        
        MOV DL, ')' 
        MOV AH, 02H
        INT 21H
        MOV DL, ':'
        INT 21H
        MOV DL, ' '
        INT 21H
        
        ; Get sort column
        MOV AH, 01H
        INT 21H
        
        ; Validate input
        SUB AL, '0'
        CMP AL, 1
        JB INVALID_SORT
        CMP AL, num_cols
        JA INVALID_SORT
        
        MOV sort_col, AL
        DEC sort_col ; Convert to 0-based index
        RET
        
    INVALID_SORT:
        LEA DX, msg_invalid
        MOV AH, 09H
        INT 21H
        JMP SORT_PROMPT_LOOP
SORT_PROMPT ENDP


; Convert string to number (handles up to 3 digits)
; Input: SI points to string
; Output: AX contains the number

CONVERT_TO_NUMBER PROC
    XOR AX, AX      ; Clear result
    XOR BX, BX      ; Clear BX for indexing
    XOR CX, CX      ; Clear CX
    
    CONVERT_LOOP:
        MOV CL, table_data[SI+BX]   ; Get character
        CMP CL, '$'                 ; Check for end of string
        JE CONVERT_DONE
        CMP CL, '0'                 ; Check if it's a digit
        JB CONVERT_DONE
        CMP CL, '9'
        JA CONVERT_DONE
        
        ; It's a digit, convert it
        SUB CL, '0'     ; Convert ASCII to number
        
        ; Multiply current result by 10 and add new digit
        MOV DX, 10
        MUL DX          ; AX = AX * 10
        ADD AX, CX      ; AX = AX + new digit
        
        INC BX
        CMP BX, MAX_STR_LEN
        JB CONVERT_LOOP
    
    CONVERT_DONE:
        RET
CONVERT_TO_NUMBER ENDP


; FIXED comparison function - Properly handles multi-digit numbers

COMPARE_ROWS PROC
    ; Calculate offset for row[j] in sort column
    MOV AL, j
    XOR AH, AH
    MOV BL, num_cols
    MUL BL             ; AX = j*num_cols
    MOV BX, MAX_STR_LEN+1
    MUL BX             ; AX = j*num_cols*(MAX_STR_LEN+1)
    MOV SI, AX         ; SI = row[j] base offset
    
    ; Add column offset
    MOV AL, sort_col
    XOR AH, AH
    MOV BX, MAX_STR_LEN+1
    MUL BX             ; AX = sort_col*(MAX_STR_LEN+1)
    ADD SI, AX         ; SI = complete offset for row[j][sort_col]
    
    ; Calculate offset for row[j+1] in sort column
    MOV AL, j
    INC AL
    XOR AH, AH
    MOV BL, num_cols
    MUL BL             ; AX = (j+1)*num_cols
    MOV BX, MAX_STR_LEN+1
    MUL BX             ; AX = (j+1)*num_cols*(MAX_STR_LEN+1)
    MOV DI, AX         ; DI = row[j+1] base offset
    
    ; Add column offset
    MOV AL, sort_col
    XOR AH, AH
    MOV BX, MAX_STR_LEN+1
    MUL BX             ; AX = sort_col*(MAX_STR_LEN+1)
    ADD DI, AX         ; DI = complete offset for row[j+1][sort_col]
    
    ; Check column type
    MOV BX, 0
    MOV BL, sort_col
    MOV AL, col_types[BX]
    
    CMP AL, 1
    JNE STRING_COMPARE_START
    JMP NUMERIC_COMPARE_START
    
    STRING_COMPARE_START:
    ; String comparison (ASCII ascending)
    MOV BX, 0
    STRING_COMPARE:
        MOV AL, table_data[SI+BX]
        MOV AH, table_data[DI+BX]
        
        ; Check for end of first string
        CMP AL, '$'
        JE STRING_1_END
        
        ; Check for end of second string
        CMP AH, '$'
        JE STRING_2_END
        
        ; Compare characters
        CMP AL, AH
        JB STRING_LESS     ; First < Second, no swap needed
        JA STRING_GREATER  ; First > Second, swap needed
        
        ; Characters equal, check next
        INC BX
        CMP BX, MAX_STR_LEN
        JB STRING_COMPARE
        JMP STRING_EQUAL
    
    STRING_1_END:
        ; First string ended, check if second also ended
        CMP AH, '$'
        JE STRING_EQUAL    ; Both ended, equal
        JMP STRING_LESS    ; First is shorter, no swap needed
    
    STRING_2_END:
        ; Second string ended but first didn't
        JMP STRING_GREATER ; First is longer, swap needed
    
    STRING_EQUAL:
        MOV AL, 0    ; No swap needed
        RET
    
    STRING_LESS:
        MOV AL, 0    ; No swap needed (correct order)
        RET
    
    STRING_GREATER:
        MOV AL, 1    ; Swap needed (wrong order)
        RET

    NUMERIC_COMPARE_START:
    ; Numeric comparison - converts strings to numbers for proper comparison
        ; Convert first number (at SI) to integer
        PUSH DI
        CALL CONVERT_TO_NUMBER  ; SI points to string, returns number in AX
        MOV BX, AX              ; Store first number in BX
        POP DI
        
        ; Convert second number (at DI) to integer  
        PUSH SI
        PUSH BX
        MOV SI, DI
        CALL CONVERT_TO_NUMBER  ; SI points to string, returns number in AX
        MOV CX, AX              ; Store second number in CX
        POP BX
        POP SI
        
        ; Compare the two numbers
        CMP BX, CX
        JA NUMERIC_GREATER      ; First > Second, swap needed
        JB NUMERIC_LESS         ; First < Second, no swap needed
        JMP NUMERIC_EQUAL       ; Equal
    
    NUMERIC_EQUAL:
        MOV AL, 0    ; No swap needed
        RET
    
    NUMERIC_LESS:
        MOV AL, 0    ; No swap needed (correct order)
        RET
    
    NUMERIC_GREATER:
        MOV AL, 1    ; Swap needed (wrong order)
        RET
COMPARE_ROWS ENDP


; Complete sorting procedure - Bubble Sort (FIXED)

SORT_TABLE PROC
    CALL SORT_PROMPT
    
    ; Check if we have enough rows to sort
    CMP num_rows, 2
    JB SORT_DONE
    
    ; Bubble sort implementation
    MOV AL, num_rows
    DEC AL
    MOV i, AL           ; i = num_rows - 1
    
    OUTER_LOOP:
        CMP i, 0
        JE SORT_DONE
        
        MOV j, 0        ; j = 0
        
        INNER_LOOP:
            MOV AL, j
            CMP AL, i
            JAE NEXT_OUTER
            
            ; Compare adjacent rows
            CALL COMPARE_ROWS
            CMP AL, 1       ; If AL = 1, swap needed
            JNE NO_SWAP
            
            CALL SWAP_ROWS
            
            NO_SWAP:
                INC j
                JMP INNER_LOOP
        
        NEXT_OUTER:
            DEC i
            JMP OUTER_LOOP
    
    SORT_DONE:
        RET
SORT_TABLE ENDP





; Row swapping function (ENHANCED)




SWAP_ROWS PROC
    ; Calculate row size in bytes
    MOV AL, num_cols
    XOR AH, AH
    MOV BX, MAX_STR_LEN+1
    MUL BX
    MOV CX, AX      ; CX = bytes per row
    
    ; Calculate offset for row[j]
    MOV AL, j
    XOR AH, AH
    MOV BL, num_cols
    MUL BL          ; AX = j * num_cols
    MOV BX, MAX_STR_LEN+1
    MUL BX          ; AX = j * num_cols * (MAX_STR_LEN+1)
    MOV SI, AX      ; SI = row[j] offset
    
    ; Calculate offset for row[j+1]
    MOV AL, j
    INC AL
    XOR AH, AH
    MOV BL, num_cols
    MUL BL          ; AX = (j+1) * num_cols
    MOV BX, MAX_STR_LEN+1
    MUL BX          ; AX = (j+1) * num_cols * (MAX_STR_LEN+1)
    MOV DI, AX      ; DI = row[j+1] offset
    
    ; Swap the rows byte by byte
    PUSH CX
    SWAP_LOOP:
        MOV AL, table_data[SI]
        MOV BL, table_data[DI]
        MOV table_data[SI], BL
        MOV table_data[DI], AL
        INC SI
        INC DI
        LOOP SWAP_LOOP
    POP CX
    
    RET
SWAP_ROWS ENDP

END MAIN