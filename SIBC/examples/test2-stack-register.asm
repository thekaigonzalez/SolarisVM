; $Id: test2-stack-register.asm

; a simple test for stack and registers
_start:
    movq R1,5
    movq R2,5

    cmp R1,R2
    je
    echo 'A'
    eeq
    jne
    echo 'B'
    eeq

  ; result - 3
