#!/bin/bash

# brainfuck interpreter

# EOF = 0
# 2**64-1 cells, both left and right of the starting position
# 8-bit values in cells, unless the environment variable INTEGERCELLS is found
# in which case it uses 64-bit integers

# it prints debug informations if the environment variable DEBUG is found


# needs bash 4.3 to reference array[-1] and to ignore NULs in the bf program
# ok one could make it work even in bash2 but whatever


# usage: bf filename-of-your-bf-program
#        bf -c 'your-bf-code-here'



debug () {
  [[ ! -v DEBUG ]] && return
  printf '\npos_tape:'
  printf '<%s>' "${pos_tape[@]}"
  printf '\nneg_tape:'
  printf '<%s>' "${neg_tape[@]}"
  printf '\nloop:'
  printf '<%s>' "${loop[@]}"
  printf '\ncell=%s i=%i j=%s code=%q bracecount=%s\n' "$cell" "$i" "$j" "${program:i:1}" "$bracecount"
} >&2

pos_tape=() neg_tape=()
declare -i cell=0 i=-1 j=0 loop=() bracecount=0

# set it to an empty value if it's set to avoid messing with the math expansion
if [[ $INTEGERCELLS ]]; then INTEGERCELLS= ; fi

# needed to read bytes correctly
LANG=C IFS=

usage () {
  echo "\
  usage: bf filename-of-your-bf-program
         bf -c 'your-bf-code-here'"
}

while getopts :hc: opt; do
  case $opt in
    h) usage; exit ;;
    c) program=$OPTARG ;;
    :) echo "Missing argument for option -$OPTARG" >&2
       usage >&2; exit 1 ;;
    *) echo "Unknown option -$OPTARG" >&2
       usage >&2; exit 1 ;;
  esac
done
shift "$(( OPTIND - 1 ))"

if (( $# > 1 )); then
  echo "Too many arguments" >&2
  usage >&2
  exit 1
elif [[ ! -v program ]]; then
  if (( $# == 0 )); then
    usage >&2
    exit 1
  elif [[ -r $1 ]]; then
    read -r -N 0 program < "$1"
  else
    echo "Couldn't read \`$1'" >&2
    exit 1
  fi
fi

while (( i++ < ${#program} )); do

  debug 

  case ${program:i:1} in

    +) if (( cell >= 0 )); then
         (( pos_tape[cell] ++ ))
       else
         (( neg_tape[-cell] ++ ))
       fi
       ;;

    -) if (( cell >= 0 )); then
         (( pos_tape[cell] -- ))
       else
         (( neg_tape[-cell] -- ))
       fi
       ;;

   \>) (( cell ++ )) ;;
   \<) (( cell -- )) ;;

    .) if (( cell >= 0 )); then
         if (( pos_tape[cell] >= 0 )); then
           printf -v output %o "$(( pos_tape[cell] % 256 ))"
         else
           printf -v output %o "$(( -(-pos_tape[cell] % 256) ))"
         fi
       else
         if (( neg_tape[-cell] >= 0 )); then
           printf -v output %o "$(( neg_tape[-cell] % 256 ))"
         else
           printf -v output %o "$(( -(-neg_tape[-cell] % 256) ))"
         fi
       fi
       printf "\\$output"
       ;;

    ,) read -r -n1 -d '' input
       # technically this is binary safe, but EOF = 0
       if (( cell >= 0 )); then
         printf -v "pos_tape[cell]" %d "'$input"
       else
         printf -v "neg_tape[-cell]" %d "'$input"
       fi
       ;;

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
         if (( cell >= 0 )); then
           if (( pos_tape[cell] ${INTEGERCELLS-% 256} == 0 )); then
             # jump
             i=j-1
           else
             loop+=(i)
           fi
         else
           if (( neg_tape[-cell] ${INTEGERCELLS-% 256} == 0 )); then
             i=j-1
           else
             loop+=(i)
           fi
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
         if (( cell >= 0 )); then
           if (( pos_tape[cell] ${INTEGERCELLS-% 256} != 0 )); then
             # jump back
             i=loop[-1]
           else
             unset "loop[-1]"
           fi
         else
           if (( neg_tape[-cell] ${INTEGERCELLS-% 256} != 0 )); then
             i=loop[-1]
           else
             unset "loop[-1]"
           fi
         fi
       else
         echo "Runtime error" >&2
         DEBUG= debug
         exit 1
       fi

  esac

done
