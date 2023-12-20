# SIBC (Solaris Intermediate Bytecode Compiler) & SLRI (Solaris Low-level Runtime Interface)

The source repository for both the Solaris Bytecode compiler (compiles LR
Assembly to SLRI) and the SLRI, the bytecode format designed to fix issues with
my previous bytecode formats, and compilers.

## SLRI

The SLRI is a bytecode format designed to be lenient, FOSS (free and open
source), portable, and easy to use and interoperate with any proper bytecode
format with.

The Solaris Bytecode VM Runtime is incredibly small, with efficiency and 
portability in mind.

There are no subroutines in the SLRI, as those are handled in the SIBC Compiler.
