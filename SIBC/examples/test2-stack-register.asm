# $Id: test2-stack-register.asm

# a simple test for stack and registers
_start:
  push 1
  push 2
  add
  pop R1
  rcl R1

  # result - 3
