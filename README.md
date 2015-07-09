# bf
A brainfuck interpreter (now a jit compiler to bash) written in bash

## FEATURES ##

- EOF = 0
- 2^64-1 cells, 2^31-1 to the left and 2^31-1 to the right of the starting position
- 8-bit values in cells
- times itself if the environment variable TIMES is found

## OPTIMIZATIONS ##

- Pointless code is removed
- Multiple increments/decrements of value and pointer are merged together
- Clear loops (`[-]` and `[+]`), possibly followed by increments/decrements, are reduced
- Shifted increments/decrements (`>>>>++<<<<`, `<<----->>`...) are reduced to a single instruction

Optimizing scan loops (`[>]` and `[<]`) doesn't make sense without `memchr`


## USAGE ##

  Usage: bf filename-of-your-bf-program
         bf -c 'your-bf-code-here'"


## CONTRIBUTORS ##

- elliott
- gniourf
