#!/usr/bin/env bash

LANG=C IFS=

getbyte () {
  [[ -t 0 ]] && exec < <(cat)   # a much better experience
  getbyte () {
    read -r -n1 -d "" input
    printf -v "tape[i]" %d "'$input"
  }
  getbyte
}
putbyte () {
  printf -v tmp %o "${tape[i]}"
  printf %b "\\$tmp"
}

if type mawk &>/dev/null; then
  awk () { mawk "$@"; }
elif type gawk &>/dev/null; then
  awk () { gawk "$@"; }
fi

prettyprint () {
  # fold because bash is extremely slow with very long lines
  #{ tr -dc "[]<>,.+-"; echo; } | fold | while read -r; do
    #len=${#REPLY}
    #for (( i = 0; i < len; i++ )); do
      #case ${REPLY:i:1} in
        #"[") if [[ ${REPLY:i:3} = "["[+-]"]" ]]; then
               #printf %s "${REPLY:i:3}"; (( i+=2 ))
             #else
               #printf "\n%*s\n%*s" "$(( ++width ))" "[" "$width"
             #fi ;;
        #"]") printf "\n%*s\n%*s" "$(( width-- ))" "]" "$width" ;;
        #*) printf %s "${REPLY:i:1}"
      #esac
    #done
  #done | awk NF

  # bash takes 56s on lostkng.b, gawk takes 1.9s, mawk 0.8s, nawk 3.2s
  { tr -dc "[]<>,.+-"; echo ; } | fold | awk '{
    for (i = 1; i <= length; i++) {
      var=substr($0,i,1)
      if (var == "[") {
        if (substr($0,i,3) ~ /\[[+-]\]/) { printf "%s", substr($0,i,3); i+=2 }
        else { printf "\n%*s", ++w, "["; printf "\n%*s", w, "" }
        }
      else if (var == "]") {
        printf "\n%*s", w--, "]"; printf "\n%*s", w, ""
      }
    else printf "%s", substr($0,i,1)
    }
  }' | awk NF
}

# note to self: extglobs literally kill performance
compile() {
  # bash's pe is just too slow for something like LostKng.b

  #program=${program//[!-[\]+.,><]}
  #program=${program//'[-]'/z}                                   # [-] and [+] are clear loops
  #program=${program//'[+]'/z}                                   # convert them to z
  #program_len=${#program}

  #while program=${program//+-}   program=${program//'<>'}       # remove pointless code
        #program=${program//-+}   program=${program//'><'}
        #program=${program//zz/z} program=${program#z}
        #program=${program//[-+]z/z}
    #(( ${#program} != program_len ))
  #do program_len=${#program}; done

  program=$(tr -dc "[]<>,.+-" <<< "$program")
  program=$(sed "
  # pntlessX: pointless code
  :pntless1
  s/+-//g; s/-+//g; s/<>//g; s/><//g; s/[-+][-+]*z/z/g; s/zzz*/z/g; s/^zz*//
  tpntless1

  s/\[[-+]]/z/g;        # z == zero this cell

  # then optimize a few common constructs

  s/>>>>>>>>>\(z*\)<<<<<<<<</a9|\1|/g;     s/<<<<<<<<<\(z*\)>>>>>>>>>/b9|\1|/g
   s/>>>>>>>>\(z*\)<<<<<<<</a8|\1|/g;       s/<<<<<<<<\(z*\)>>>>>>>>/b8|\1|/g
    s/>>>>>>>\(z*\)<<<<<<</a7|\1|/g;         s/<<<<<<<\(z*\)>>>>>>>/b7|\1|/g
     s/>>>>>>\(z*\)<<<<<</a6|\1|/g;           s/<<<<<<\(z*\)>>>>>>/b6|\1|/g
      s/>>>>>\(z*\)<<<<</a5|\1|/g;             s/<<<<<\(z*\)>>>>>/b5|\1|/g
       s/>>>>\(z*\)<<<</a4|\1|/g;               s/<<<<\(z*\)>>>>/b4|\1|/g
        s/>>>\(z*\)<<</a3|\1|/g;                 s/<<<\(z*\)>>>/b3|\1|/g
         s/>>\(z*\)<</a2|\1|/g;                   s/<<\(z*\)>>/b2|\1|/g
          s/>\(z*\)</a1|\1|/g;                     s/<\(z*\)>/b1|\1|/g
  s/>>>>>>>>>\(+*\)<<<<<<<<</a9|\1|/g;     s/<<<<<<<<<\(+*\)>>>>>>>>>/b9|\1|/g
   s/>>>>>>>>\(+*\)<<<<<<<</a8|\1|/g;       s/<<<<<<<<\(+*\)>>>>>>>>/b8|\1|/g
    s/>>>>>>>\(+*\)<<<<<<</a7|\1|/g;         s/<<<<<<<\(+*\)>>>>>>>/b7|\1|/g
     s/>>>>>>\(+*\)<<<<<</a6|\1|/g;           s/<<<<<<\(+*\)>>>>>>/b6|\1|/g
      s/>>>>>\(+*\)<<<<</a5|\1|/g;             s/<<<<<\(+*\)>>>>>/b5|\1|/g
       s/>>>>\(+*\)<<<</a4|\1|/g;               s/<<<<\(+*\)>>>>/b4|\1|/g
        s/>>>\(+*\)<<</a3|\1|/g;                 s/<<<\(+*\)>>>/b3|\1|/g
         s/>>\(+*\)<</a2|\1|/g;                   s/<<\(+*\)>>/b2|\1|/g
          s/>\(+*\)</a1|\1|/g;                     s/<\(+*\)>/b1|\1|/g
  s/>>>>>>>>>\(-*\)<<<<<<<<</a9|\1|/g;     s/<<<<<<<<<\(-*\)>>>>>>>>>/b9|\1|/g
   s/>>>>>>>>\(-*\)<<<<<<<</a8|\1|/g;       s/<<<<<<<<\(-*\)>>>>>>>>/b8|\1|/g
    s/>>>>>>>\(-*\)<<<<<<</a7|\1|/g;         s/<<<<<<<\(-*\)>>>>>>>/b7|\1|/g
     s/>>>>>>\(-*\)<<<<<</a6|\1|/g;           s/<<<<<<\(-*\)>>>>>>/b6|\1|/g
      s/>>>>>\(-*\)<<<<</a5|\1|/g;             s/<<<<<\(-*\)>>>>>/b5|\1|/g
       s/>>>>\(-*\)<<<</a4|\1|/g;               s/<<<<\(-*\)>>>>/b4|\1|/g
        s/>>>\(-*\)<<</a3|\1|/g;                 s/<<<\(-*\)>>>/b3|\1|/g
         s/>>\(-*\)<</a2|\1|/g;                   s/<<\(-*\)>>/b2|\1|/g
          s/>\(-*\)</a1|\1|/g;                     s/<\(-*\)>/b1|\1|/g

  :pntless2
  s/+\([ab][0-9]|[^|]*|\)-/\1/g;           s/-\([ab][0-9]|[^|]*|\)+/\1/g
  s/+\([ab][0-9]|[^|]*|\)+/++\1/g;         s/-\([ab][0-9]|[^|]*|\)-/--\1/g
  tpntless2

  :pntless3
  s/\([ab][0-9]\)|\([^|]*\)|\1|/\1|\2/g
  tpntless3

  # repeat pntless1, + extra check for something like a7||
  # clean junk generated in pntless3
  :pntless4
  s/+-//g; s/-+//g; s/<>//g; s/><//g; s/[-+][-+]*z/z/g; s/zzz*/z/g; s/^zz*//
  s/\([ab][0-9]\)||//g
  tpntless4

  " <<< "$program")
  program_len=${#program}

  local -i i j count
  local ins

  echo "go () { tape=() i=0"                                     # beginning of function
  #echo "go () { tape=(0{,,,,}{,,,,}{,,,,}{,,,,}{,,,,}{,,,}{,,,}{,}) i=0"

  # deadcode elimination may take a lot for long programs
  if [[ -v DEADCODE ]]; then
    while [[ $program = ["[z"]* ]]; do                           # remove starting loops
      [[ $program = z* ]] || lvl=1
      while (( ++i < program_len && lvl )); do
        case ${program:i:1} in
          "[") (( lvl ++ )) ;;
          "]") (( lvl -- )) ;;
        esac
      done
      program=${program:i}
      (( program_len -= i, i = 0 ))
    done
    while [[ $program =~ (.*)("]["|"]"zz*|"["zz*"]")(.*) ]]; do  # remove loops after a loop
      if [[ ${BASH_REMATCH[2]} = "["* ]]; then
        program=${BASH_REMATCH[1]}z${BASH_REMATCH[3]}
      elif [[ ${BASH_REMATCH[2]} = "]z"* ]]; then
        program="${BASH_REMATCH[1]}]${BASH_REMATCH[3]}"
      else
        tmp=${BASH_REMATCH[2]#"]"}${BASH_REMATCH[3]}
        i=0 tmp_len=${#tmp}
        while [[ $tmp = ["["]* ]]; do
          for (( lvl = 1; ++i < tmp_len && lvl; )); do
            case ${tmp:i:1} in
              "[") (( lvl ++ )) ;;
              "]") (( lvl -- )) ;;
            esac
          done
          tmp=${tmp:i}
          (( tmp_len -= i, i = 0 ))
        done
        program="${BASH_REMATCH[1]}]$tmp"
      fi
      program_len=${#program}
    done
  fi

  # todo
  # this takes a lot in any case...
  #if [[ -v PRECOMPUTE ]]; then
    ## precompile what is always known at compile time
    #newprogram=${program%%[,.]*}
    #if (( ${#newprogram} < ${#program} )); then
      ## remove loops until it's safe to eval
      #while looponly=${newprogram//[![\]]}
        #open=${looponly//\[}
        #close=${looponly//\]}
        #(( ${#open} != ${#close} ))
      #do
        #newprogram=${newprogram%[[\]]*}
        #echo -n . >&2
      #done

      #declare -p newprogram >&2
      #(
        #program=$newprogram
        #program_len=${#program}
        #compiled=$(compile 2>/dev/null)
        #eval "$compiled"
        #declare -f go >&2
        #go
        ##echo here >&2
        #declare -p tape i
        #declare -p tape i >&2
      #)
      #program=${program#"$newprogram"}
      #program_len=${#program}
    #fi
  #fi


  while (( i < program_len )); do
    ins=${program:i:1}
    case $ins in
    +|-|">"|"<")                                                 # squeeze these
      for (( count = 1; ++i < program_len; count ++ )); do
        [[ ${program:i:1} = "$ins" ]] || break
      done
      case $ins in
          -) echo -n "(( tape[i] = (tape[i] - $count) & 255 ));" ;;
          +) echo -n "(( tape[i] = (tape[i] + $count) & 255 ));" ;;
        ">") echo -n "(( i += $count ));" ;;
        "<") echo -n "(( i -= $count ));" ;;
      esac
      ;;
    .) echo putbyte; (( i ++ )) ;;
    ,) echo getbyte; (( i ++ )) ;;
    "[")
                                                                 # optimize multiplication loops
      loop=${program:i+1} loop=${loop%%"]"*}

      if [[ $loop = *[",.["]* ]]; then
        echo "while (( tape[i] )); do"
      else
        left=${loop//[!<]} right=${loop//[!>]}
        if (( ${#left} != ${#right} )); then
          echo "while (( tape[i] )); do"
        else
          min=0 loop_len=${#loop} tape_pos=0                     # 2 steps because array[-1]
          for (( loop_i = 0; loop_i < loop_len; loop_i++)); do
            case ${loop:loop_i:1} in
              "<") (( min = -- tape_pos < min ? tape_pos : min )); ;;
              ">") (( tape_pos ++ )) ;;
              b) (( min = tape_pos - ${loop:loop_i+1:1} < min ? tape_pos - ${loop:loop_i+1:1} : min ))
                                                                 # any other character is skipped
            esac
          done
          starting_pos=${min#-} tape=([starting_pos]=0)
          tape_pos=$starting_pos if=0
          for (( loop_i = 0; loop_i < loop_len; loop_i++)); do   # mini interpreter
            case ${loop:loop_i:1} in
              "<") (( tape_pos -- )) ;;
              ">") (( tape_pos ++ )) ;;
              +) (( tape[tape_pos] = (tape[tape_pos] + 1) & 255 )) ;;
              -) (( tape[tape_pos] = (tape[tape_pos] - 1) & 255 )) ;;
              z) tape[tape_pos]=0 ; if=1 ;;
              a|b) jump=${loop:loop_i+1:1}
                 [[ ${loop:loop_i:1} = a ]] && dire=+ || dire=-
                 (( tape_pos $dire= jump, loop_i += 3 ))         # now we're past |
                 while :; do
                   case ${loop:loop_i:1} in
                     +) (( tape[tape_pos] ++ )) ;;
                     -) (( tape[tape_pos] -- )) ;;
                     z) tape[tape_pos]=0 ; if=1 ;;
                     *) break
                   esac
                   (( loop_i ++ ))
                 done
                 if [[ $dire = + ]]; then (( tape_pos -= jump ))
                 else (( tape_pos += jump ))
                 fi
                 ;;
            esac
          done
          strings=()
          case ${tape[starting_pos]} in                          # +/-1 == optimize it away
            1) for position in "${!tape[@]}"; do
                 (( tape[position] *= -1 ))                      # convert [+>--<] to [->++<]
               done ;&
            255) for position in "${!tape[@]}"; do
                   offset=$((position-starting_pos)) string=
                   case $offset in
                     0) continue ;;
                     [!-]*) offset=+$offset ;&
                     *) string="tape[i$offset] = " ;;
                   esac
                   if (( tape[position] == 0 )); then
                     string+=0
                   elif (( tape[position] > 0 )); then
                     string+="(tape[i$offset] + tape[i] * ${tape[position]}) & 255"
                   else
                     string+="(tape[i$offset] - tape[i] * ${tape[position]#-}) & 255"
                   fi
                   strings+=("$string")
                 done
                 (( if )) && echo "if (( tape[i] )); then"
                 printf "(( ${strings[0]//" * 1)"/)} "
                 for string in "${strings[@]:1}"; do
                   printf ", ${string//" * 1)"/)} "
                 done
                 echo -n ", tape[i] = 0 ));"
                 (( if )) && echo fi
                 (( i += ${#loop} + 1 ))
              ;;
            0) for position in "${!tape[@]}"; do
                 offset=$((position-starting_pos)) string=
                 case $offset in
                   0) continue ;;
                   [!-]*) offset=+$offset ;&
                   *) string="tape[i$offset] = " ;;
                 esac
                 if (( tape[position] == 0 )); then
                   string+=0
                 elif (( tape[position] > 0 )); then
                   string+="(tape[i$offset] + ${tape[position]}) & 255"
                 else
                   string+="(tape[i$offset] - ${tape[position]#-}) & 255"
                 fi
                 strings+=("$string")
               done
               if (( if )); then
                 echo "if (( tape[i] )); then"
               else
                 echo "while (( tape[i] )); do"
               fi
               printf "(( ${strings[0]//" * 1)"/)} "
               for string in "${strings[@]:1}"; do
                 printf ", ${string//" * 1)"/)} "
               done
               if (( if )); then
                 echo ", tape[i] = 0 )); fi"
                 (( i += ${#loop} + 1 ))
               else
                 (( i += ${#loop} ))
                 echo -n "));"
               fi
               ;;
            *) echo "while (( tape[i] )); do"               # so much work for nothing
          esac
        fi
      fi


         [[ ${program:(++i):1} = "]" ]] && echo ":;" ;;          # syntax error without this
    "]") echo done; (( i ++ ))
       ;;
    a|b) count=${program:(++i):1} op=${program:(++i,++i):1}
         for (( incrcount = 1; ++i < program_len; incrcount ++ )); do
           [[ ${program:i:1} = [z+-] ]] || break
         done
         (( i++ ))                                               # skip the | separator
         if [[ $op = z ]]; then
           case $ins in
             a) echo -n "(( tape[i+$count] = 0 ));" ;;
             b) echo -n "(( tape[i-$count] = 0 ));" ;;
           esac
         else
           case $ins in
             a) echo -n "(( tape[i+$count] = (tape[i+$count] $op $incrcount) & 255 ));" ;;
             b) echo -n "(( tape[i-$count] = (tape[i-$count] $op $incrcount) & 255 ));" ;;
           esac
         fi
         ;;
    z) for (( count = 0; ++i < program_len; count ++ )); do      # optimize [-]++++
         [[ ${program:i:1} = [+-] ]] || break
       done
       echo -n "tape[i]=$((count & 255));"
       ;;
    esac
  done
  echo }                                                         # end of function
}

case $# in
  1) program=$(< "$1") ;;
  2) [[ $1 = -c ]] || exit 1
     program=$2 ;;
  *) exit 1
esac

[[ -v PRETTY ]] && prettyprint <<< "$program" && exit
# aliases because why not
[[ -v TIMES ]] || alias time=                                    # TIMES= ./bf myprogram.b

shopt -s expand_aliases
TIMEFORMAT="compilation time: real: %lR, user: %lU, sys: %lS"
time compiled=$(compile | sed -e:a -e's/));((/,/g;s/));\(tape[^;]*\);/, \1 ));/g;ta')
shopt -u expand_aliases

eval "$compiled" || exit 1                                       # create that function

prettyprint () {
  echo LANG=C IFS=
  [[ $compiled = *getbyte* ]] && declare -f getbyte
  [[ $compiled = *putbyte* ]] && declare -f putbyte
  declare -f go | sed 1d
  exit
}
[[ -v PRINT ]] && prettyprint
shopt -s expand_aliases
TIMEFORMAT=$'\nexecution time: real: %lR, user: %lU, sys: %lS'
time go
exit 0
