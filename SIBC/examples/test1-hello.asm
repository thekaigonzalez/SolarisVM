; $Id: test1-hello.asm

a:
    echo 'a'
    echo 'b'
    echo 'c'
    echo 0x0a

_start:
    jmp a
