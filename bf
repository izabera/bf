#!/bin/bash

# brainfuck interpreter

# EOF = 0
# 2**63-1 cells
# trying to write to a cell in the left part of the tape causes a runtime error
# 8-bit values in cells, unless the environment variable INTEGERCELLS is found
# in which case it uses 64-bit integers

# it prints debug informations if the environment variable DEBUG is found


# needs bash 4.3 to reference array[-1] and to ignore NULs in the bf program
# ok one could make it work even in bash2 but whatever


# usage: ./bf filename-of-your-bf-program



debug () {
  [[ ! -v DEBUG ]] && return
  printf tape:
  printf '<%s>' "${tape[@]}"
  echo
  printf loop:
  printf '<%s>' "${loop[@]}"
  echo
  echo "cell=$cell i=$i j=$j code=${program:i:1} bracecount=$bracecount"
  echo
} >&2

tape=()
declare -i cell=0 i=-1 j=0 loop=()

# set it to an empty value if it's set to avoid messing with the math expansion
if [[ $INTEGERCELLS ]]; then INTEGERCELLS= ; fi

if (( $# != 1 )); then
  echo "usage: ./bf filename-of-your-bf-program" >&2
  exit 1
elif [[ -r $1 ]]; then
  read -r -N 0 program < "$1"
else
  echo "Couldn't read \`$1'" >&2
  exit 1
fi

while (( i++ < ${#program} )); do

  debug 

  case ${program:i:1} in

    +) if (( cell >= 0 )); then
         (( tape[cell] ++ ))
       else
         echo "Runtime error: x" >&2
         debug= debug
         exit 1
       fi
       ;;

    -) if (( cell >= 0 )); then
         (( tape[cell] -- ))
       else
         echo "Runtime error" >&2
         debug= debug
         exit 1
       fi
       ;;

   \>) (( cell ++ )) ;;
   \<) (( cell -- )) ;;

    .) printf -v output %o "$(( tape[cell] ${INTEGERCELLS-+ 256 % 256} ))"
       printf "\\$output" ;;

    ,) IFS= read -r -n1 -d '' input
       # technically this is binary safe, but EOF = 0
       printf -v "tape[cell]" %d "'$input" ;;

   \[) # find the closing ]
       # if it's missing, error out and quit
       bracecount=1 j=i
       while (( j++ < ${#program} && bracecount > 0 )); do
         case ${program:j:1} in
          \[) (( bracecount ++ )) ;;
          \]) (( bracecount -- )) ;;
         esac
       done

       if (( bracecount == 0 )); then
         # we found the closing ]
         if (( tape[cell] ${INTEGERCELLS-+ 256 % 256} == 0 )); then
           # jump
           i=j-1
         else
           loop+=(i)
         fi
       else
         echo "Runtime error" >&2
         DEBUG= debug
         exit 1
       fi
       ;;
       
   \]) # go back to the previous [
       # if it's missing, error out and quit
       if (( ${#loop[@]} )); then
         if (( tape[cell] ${INTEGERCELLS-+ 256 % 256} != 0 )); then
           # jump back
           i=loop[-1]
         else
           unset "loop[-1]"
         fi
       else
         echo "Runtime error" >&2
         DEBUG= debug
         exit 1
       fi

  esac

done
