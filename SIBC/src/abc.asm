[compat nexfuse]

_start:
    echo 'A'
    jmp b

b:
    echo 'B'
    jmp c

c:
    echo 'C'
    echo 0x0a
    ; end
