# bf
A brainfuck interpreter (a jit compiler to bash) written in bash

## FEATURES ##

- EOF = 0
- 2^64-1 cells to the right of the start position (can be easily changed to start in the middle but it's slower)
- 8-bit unsigned values in cells
- times itself if the environment variable TIMES is found
- prints the compiled code if the environment variable PRINT is found
- pretty prints the brainfuck code if the environment variable PRETTY is found
- removes as much dead code as possible if the environment variable DEADCODE is found

## OPTIMIZATIONS ##

- Pointless code is removed
- Multiple increments/decrements of value and pointer are merged together
- Clear loops (`[-]` and `[+]`), possibly followed by increments/decrements, are reduced
- Shifted increments/decrements (`>>>>++<<<<`, `<<----->>`...) are reduced to a single instruction
- Loops that multiply a single cell are reduced to two instructions

Optimizing scan loops (`[>]` and `[<]`) doesn't make sense in bash

## TODO ##

- Multiplication loops done properly
- Precompute tape
- moar


## USAGE ##

```
bf filename-of-your-bf-program
bf -c 'your-bf-code-here'
```


## BUGS ##

It's extremely slow compared to anything that compiles to c or to assembly.

That said, it's probably faster than many interpreters written in "faster" languages.


## CONTRIBUTORS ##

- elliott
- gniourf
