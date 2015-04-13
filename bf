#!/bin/bash

# brainfuck interpreter

# EOF = 0
# 2**64-1 cells, both left and right of the starting position
# 8-bit values in cells, unless the environment variable INTEGERCELLS is found
# in which case it uses 64-bit integers

# it prints debug informations if the environment variable DEBUG is found


# tested in bash 4.3
# probably works in older versions too but i don't really care


# Usage: bf filename-of-your-bf-program
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
  Usage: bf [-s] filename-of-your-bf-program
         bf [-s] -c 'your-bf-code-here'"
}

shopt -s expand_aliases
# hack to completely remove the code
# the aliases are expanded only once
alias _=

while getopts :hsc: opt; do
  case $opt in
    h) usage; exit ;;
    c) program=$OPTARG ;;
    s) alias debug= _=# ;;
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

# 2. explode the string into an array
# try to optimize the bf code:
# keep +/-/>/< tokens together and append the number of times
i=-1 count=1
while (( i++ <= ${#program} )); do
  # up to <= so that the last one expands to empty

  if [[ ${#code[@]} -gt 0 && ${code[-1]} = @(+|-|<|>) ]]; then
    if [[ ${code[-1]} != "${program:i:1}" ]]; then
      code[-1]+=$count
      code+=("${program:i:1}")
      count=1
    else
      (( count++ ))
    fi
  else
    code+=("${program:i:1}")
  fi

done
len=${#code[@]}

# 3. precompute the jumps  (faster code made by gniourf!)
open_brackets=()
i=0
for ((i=0;i<len;++i)); do
   char=${code[i]}
   code+=( "$char" )
   case $char in
      ('[') open_brackets=( "$i" "${open_brackets[@]}" ) ;;
      (']')
            if ((${#open_brackets[@]}==0)); then
               printf >&2 'Missing [\n'
               exit 1
            fi
            jump[i]=${open_brackets[0]}
            jump[${open_brackets[0]}]=$i
            open_brackets=( "${open_brackets[@]:1}" )
            ;;
   esac
done
if ((${#open_brackets[@]})); then
   printf >&2 'Missing ]\n'
   exit 1
fi





i=-1
while (( i++ < len )); do

  debug 

  case ${code[i]} in

   +*) _ if (( cell >= 0 )); then
           (( pos_tape[cell] += ${code[i]#?} ))
       _ else
       _   (( neg_tape[-cell] += ${code[i]#?} ))
       _ fi
       ;;

   -*) _ if (( cell >= 0 )); then
           (( pos_tape[cell] -= ${code[i]#?} ))
       _ else
       _   (( neg_tape[-cell] -= ${code[i]#?} ))
       _ fi
       ;;

 '>'*) (( cell += ${code[i]#?} )) ;;
 '<'*) (( cell -= ${code[i]#?} )) ;;

    .) _ if (( cell >= 0 )); then
           if (( pos_tape[cell] >= 0 )); then
             printf -v output %o "$(( pos_tape[cell] % 256 ))"
           else
             printf -v output %o "$(( -(-pos_tape[cell] % 256) ))"
           fi
       _ else
       _   if (( neg_tape[-cell] >= 0 )); then
       _     printf -v output %o "$(( neg_tape[-cell] % 256 ))"
       _   else
       _     printf -v output %o "$(( -(-neg_tape[-cell] % 256) ))"
       _   fi
       _ fi
       printf "\\$output"
       ;;

    ,) read -r -n1 -d '' input
       # technically this read is binary safe, but EOF = 0
       _ if (( cell >= 0 )); then
           printf -v "pos_tape[cell]" %d "'$input"
       _ else
       _   printf -v "neg_tape[-cell]" %d "'$input"
       _ fi
       ;;

  '[') _ if (( cell >= 0 )); then
           if (( pos_tape[cell] ${INTEGERCELLS-% 256} == 0 )); then
             # jump forward
             i=jump[i]
           fi
       _ else
       _   if (( neg_tape[-cell] ${INTEGERCELLS-% 256} == 0 )); then
       _     i=jump[i]
       _   fi
       _ fi
       ;;
       
  ']') _ if (( cell >= 0 )); then
           if (( pos_tape[cell] ${INTEGERCELLS-% 256} != 0 )); then
             # jump back
             i=jump[i]
           fi
       _ else
       _   if (( neg_tape[-cell] ${INTEGERCELLS-% 256} != 0 )); then
       _     i=jump[i]
       _   fi
       _ fi

  esac

done
