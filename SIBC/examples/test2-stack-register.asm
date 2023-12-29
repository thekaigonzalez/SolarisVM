; $Id: test2-stack-register.asm

; a simple test for stack and registers
_start:
    movq R1,5
    movq R2,4

    cmp R1,R2
    ; if R1 == R2
    je
        echo 'A'
        echo 'B'
        echo 'C'
    eeq
    ; note: eeq stands for ENDEQ, i.e. end of equal
    ; this is required for the 'cmp' instruction
    ; if R1 != R2
    jne
        jmp false
    eeq

false:
    echo 'D'
    echo 'E'
    echo 'F'
; for false
