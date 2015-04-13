# bf
A brainfuck interpreter written in bash


I'm in #esoteric and i kinda felt out of place without knowing brainfuck
so I decided to teach it myself by writing an interpreter.

And TADA!... now I know brainfuck


## FEATURES ##

- EOF = 0
- 2^64-1 cells, 2^31-1 to the left and 2^31-1 to the right of the starting position
- 8-bit values in cells, unless the environment variable INTEGERCELLS is found
  in which case it uses 64-bit integers
- it prints debug informations if the environment variable DEBUG is found




Beware: it's *SLOOOOOOOOOOOOW* (but it works)

Note: much much faster than the first naïve version
