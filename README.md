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



## OPTIMIZATIONS ##

It turns out that bash is slow...  (surprise!)

My first naïve version could run rot13 at a rate of 5s per letter...
That was horrifiying :(

Now the interpreter merges together multiple increments/decrements of the value
and the pointer.

It also builds a list of all the jumps before actually running the code.  This
was a major speedup.


## USAGE ##

  Usage: bf [-s] filename-of-your-bf-program
         bf [-s] -c 'your-bf-code-here'"

If the -s option is passed:
  - the debug features are completely disabled
  - the tape is one-sided (trying to get/set values on the left side simply fails)


## CONTRIBUTORS ##

- elliott
- gniourf
