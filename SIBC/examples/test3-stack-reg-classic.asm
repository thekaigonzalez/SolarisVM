; $Id: test3-stack-reg-classic.asm

a:
    echo 'A'
    echo 'B'
    echo 'C'
b:
    echo 'D'
    echo 'E'
    echo 'F'

; a simple test for stack and registers
m:
    mov R1,5
    mov R2,5

    cmp R1,R2,a,b
