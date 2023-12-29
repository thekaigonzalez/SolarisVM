; $Id: test4-stdin.asm

[compat solaris]

_start:
    movq R2,'A'
    movq R2,'B'
    movq R2,'C'

    in R1
    in R1
    in R1

    cmp R1,R2
    je
        echo 'D'
        echo 'E'
        echo 'F'
    eeq

    jne
        jmp false
    eeq

false:
    echo 'G'
    echo 'H'
    echo 'I'
