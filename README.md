# bf
A brainfuck interpreter (now a jit compiler to bash) written in bash

## FEATURES ##

- EOF = 0
- 2^64-1 cells, 2^31-1 to the left and 2^31-1 to the right of the starting position
- 8-bit values in cells
- times itself if the environment variable TIMES is found
- prints the compiled code if the environment variable PRINT is found
- pretty prints the brainfuck code if the environment variable PRETTY is found
- removes as much dead code as possible if the environment variable DEADCODE is found

## OPTIMIZATIONS ##

- Pointless code is removed
- Multiple increments/decrements of value and pointer are merged together
- Clear loops (`[-]` and `[+]`), possibly followed by increments/decrements, are reduced
- Shifted increments/decrements (`>>>>++<<<<`, `<<----->>`...) are reduced to a single instruction

Optimizing scan loops (`[>]` and `[<]`) doesn't make sense in bash

## TODO ##

- Multiplication loops
- moar


## USAGE ##

  Usage: bf filename-of-your-bf-program
         bf -c 'your-bf-code-here'"


## CONTRIBUTORS ##

- elliott
- gniourf
