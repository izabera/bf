#!/bin/bash

# brainfuck interpreter

# EOF = 0
# 2**64-1 cells, both left and right of the starting position
# 8-bit values in cells, unless the environment variable INTEGERCELLS is found
# in which case it uses 64-bit integers

# it prints debug informations if the environment variable DEBUG is found


# tested in bash 4.3
# probably works in older versions too but i don't really care


# usage: bf filename-of-your-bf-program
#        bf -c 'your-bf-code-here'



debug () {
  [[ ! -v DEBUG ]] && return
  printf '\npos_tape:'
  printf '<%s>' "${pos_tape[@]}"
  printf '\nneg_tape:'
  printf '<%s>' "${neg_tape[@]}"
  printf '\njump:'
  printf '<%s>' "${jump[@]}"
  printf '\ncell=%s i=%i code=%s\n' "$cell" "$i" "${code[i]}"
} >&2

pos_tape=() neg_tape=()
declare -i cell=0 i j jump=() bracecount

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
    program=$(< "$1")
  else
    echo "Couldn't read \`$1'" >&2
    exit 1
  fi
fi





# before we begin to loop, speed up as much as possible

# 1. strip unnecessary crap
program=${program//[!-[\]+.,><]}
len=${#program}

# 2. explode the string into an array
i=-1
while (( i++ < len )); do
  code+=("${program:i:1}")
done

# 3. precompute the jumps
bracecount=0 i=-1
while (( i++ < len )); do
  case ${code[i]} in
   '[') (( bracecount ++ )) ;;
   ']') (( bracecount -- )) ;;
  esac
done

if (( bracecount > 0 )); then
  echo "Missing ]" >&2
  exit 1
elif (( bracecount < 0 )); then
  echo "Missing [" >&2
  exit 1
fi

# TODO: merge this in the previous loop
i=-1
while (( i++ < len )); do

  if [[ ${code[i]} = '[' ]]; then
    bracecount=1 j=i 

    # this loop always finds the match
    while (( j++ < len && bracecount > 0 )); do
      case ${code[j]} in
        '[') (( bracecount ++ )) ;;
        ']') (( bracecount -- )) ;;
      esac
    done

    jump[i]=j-1

  elif [[ ${code[i]} = ']' ]]; then
    bracecount=-1 j=i

    while (( j-- >= 0 && bracecount < 0 )); do
      case ${code[j]} in
        '[') (( bracecount ++ )) ;;
        ']') (( bracecount -- )) ;;
      esac
    done

    jump[i]=j+1

  fi
done





i=-1
while (( i++ < len )); do

  debug 

  case ${code[i]} in

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

  '>') (( cell ++ )) ;;
  '<') (( cell -- )) ;;

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
       # technically this read is binary safe, but EOF = 0
       if (( cell >= 0 )); then
         printf -v "pos_tape[cell]" %d "'$input"
       else
         printf -v "neg_tape[-cell]" %d "'$input"
       fi
       ;;

  '[') if (( cell >= 0 )); then
         if (( pos_tape[cell] ${INTEGERCELLS-% 256} == 0 )); then
           # jump forward
           i=jump[i]
         fi
       else
         if (( neg_tape[-cell] ${INTEGERCELLS-% 256} == 0 )); then
           i=jump[i]
         fi
       fi
       ;;
       
  ']') if (( cell >= 0 )); then
         if (( pos_tape[cell] ${INTEGERCELLS-% 256} != 0 )); then
           # jump back
           i=jump[i]
         fi
       else
         if (( neg_tape[-cell] ${INTEGERCELLS-% 256} != 0 )); then
           i=jump[i]
         fi
       fi

  esac

done
