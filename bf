#!/usr/bin/env bash

LANG=C IFS=

getbyte () {
  read -r -n1 -d "" input
  printf -v "tape[i]" %d "'$input"
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
  program=$(sed ":while
                        # pointless code
  s/+-//g; s/-+//g; s/<>//g; s/><//g; s/[-+][-+]*z/z/g; s/zzz*/z/g; s/^zz*//
  t while
                        
  s/\[[-+]]/z/g;        # z == zero this cell

                        # then optimize a few common constructs

  s/>>>>>>>>>\(z*\)<<<<<<<<</a9|\1|/g;    s/<<<<<<<<<\(z*\)>>>>>>>>>/b9|\1|/g
   s/>>>>>>>>\(z*\)<<<<<<<</a8|\1|/g;      s/<<<<<<<<\(z*\)>>>>>>>>/b8|\1|/g
    s/>>>>>>>\(z*\)<<<<<<</a7|\1|/g;        s/<<<<<<<\(z*\)>>>>>>>/b7|\1|/g
     s/>>>>>>\(z*\)<<<<<</a6|\1|/g;          s/<<<<<<\(z*\)>>>>>>/b6|\1|/g
      s/>>>>>\(z*\)<<<<</a5|\1|/g;            s/<<<<<\(z*\)>>>>>/b5|\1|/g
       s/>>>>\(z*\)<<<</a4|\1|/g;              s/<<<<\(z*\)>>>>/b4|\1|/g
        s/>>>\(z*\)<<</a3|\1|/g;                s/<<<\(z*\)>>>/b3|\1|/g
         s/>>\(z*\)<</a2|\1|/g;                  s/<<\(z*\)>>/b2|\1|/g
          s/>\(z*\)</a1|\1|/g;                    s/<\(z*\)>/b1|\1|/g
  s/>>>>>>>>>\(+*\)<<<<<<<<</a9|\1|/g;    s/<<<<<<<<<\(+*\)>>>>>>>>>/b9|\1|/g
   s/>>>>>>>>\(+*\)<<<<<<<</a8|\1|/g;      s/<<<<<<<<\(+*\)>>>>>>>>/b8|\1|/g
    s/>>>>>>>\(+*\)<<<<<<</a7|\1|/g;        s/<<<<<<<\(+*\)>>>>>>>/b7|\1|/g
     s/>>>>>>\(+*\)<<<<<</a6|\1|/g;          s/<<<<<<\(+*\)>>>>>>/b6|\1|/g
      s/>>>>>\(+*\)<<<<</a5|\1|/g;            s/<<<<<\(+*\)>>>>>/b5|\1|/g
       s/>>>>\(+*\)<<<</a4|\1|/g;              s/<<<<\(+*\)>>>>/b4|\1|/g
        s/>>>\(+*\)<<</a3|\1|/g;                s/<<<\(+*\)>>>/b3|\1|/g
         s/>>\(+*\)<</a2|\1|/g;                  s/<<\(+*\)>>/b2|\1|/g
          s/>\(+*\)</a1|\1|/g;                    s/<\(+*\)>/b1|\1|/g
  s/>>>>>>>>>\(-*\)<<<<<<<<</a9|\1|/g;    s/<<<<<<<<<\(-*\)>>>>>>>>>/b9|\1|/g
   s/>>>>>>>>\(-*\)<<<<<<<</a8|\1|/g;      s/<<<<<<<<\(-*\)>>>>>>>>/b8|\1|/g
    s/>>>>>>>\(-*\)<<<<<<</a7|\1|/g;        s/<<<<<<<\(-*\)>>>>>>>/b7|\1|/g
     s/>>>>>>\(-*\)<<<<<</a6|\1|/g;          s/<<<<<<\(-*\)>>>>>>/b6|\1|/g
      s/>>>>>\(-*\)<<<<</a5|\1|/g;            s/<<<<<\(-*\)>>>>>/b5|\1|/g
       s/>>>>\(-*\)<<<</a4|\1|/g;              s/<<<<\(-*\)>>>>/b4|\1|/g
        s/>>>\(-*\)<<</a3|\1|/g;                s/<<<\(-*\)>>>/b3|\1|/g
         s/>>\(-*\)<</a2|\1|/g;                  s/<<\(-*\)>>/b2|\1|/g
          s/>\(-*\)</a1|\1|/g;                    s/<\(-*\)>/b1|\1|/g
  " <<< "$program")
  program_len=${#program}


  echo "go () { tape=() i=0"                                     # beginning of function

  local -i i j tmp count
  local ins
  while (( i < program_len )); do
    ins=${program:i:1}
    case $ins in
    +|-|">"|"<")                                                 # squeeze these
      for (( count = 1; ++i < program_len; count ++ )); do
        [[ ${program:i:1} = "$ins" ]] || break
      done
      case $ins in
          -) echo "(( tape[i] = (tape[i] - $count) & 255 ))" ;;
          +) echo "(( tape[i] = (tape[i] + $count) & 255 ))" ;;
        ">") echo "(( i += $count ))" ;;
        "<") echo "(( i -= $count ))" ;;
      esac
      ;;
    .) echo 'printf -v tmp %o "${tape[i]}"; printf %b "\\$tmp"'; (( i ++ )) ;;
    ,) echo getbyte ; (( i ++ )) ;;
    "[") echo "while (( tape[i] != 0 )); do :;"; (( i ++ )) ;;   # :; because of []
    "]") echo done; (( i ++ )) ;;
    a|b) count=${program:(++i):1} op=${program:(++i,++i):1}
         for (( incrcount = 1; ++i < program_len; incrcount ++ )); do
           [[ ${program:i:1} = [z+-] ]] || break
         done
         (( i++ ))                                               # skip the | separator
         if [[ $op = z ]]; then
           case $ins in
             a) echo "(( tape[i+$count] = 0 ))" ;;
             b) echo "(( tape[i-$count] = 0 ))" ;;
           esac
         else
           case $ins in
             a) echo "(( tape[i+$count] $op= $incrcount ))" ;;
             b) echo "(( tape[i-$count] $op= $incrcount ))" ;;
           esac
         fi
         ;;
    z) for (( count = 0; ++i < program_len; count ++ )); do      # optimize [-]++++
         [[ ${program:i:1} = [+-] ]] || break
       done
       echo "tape[i]=$count" ;;
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

[[ -v TIMES ]] || alias time=                                    # TIMES= ./bf myprogram.b
shopt -s expand_aliases
TIMEFORMAT="compilation time: real: %lR, user: %lU, sys: %lS"
time compiled=$(compile)
shopt -u expand_aliases

eval "$compiled" || exit 1                                       # create that function

shopt -s expand_aliases
#declare -f go; exit     # pretty printing
TIMEFORMAT=$'\nexecution time: real: %lR, user: %lU, sys: %lS'
time go
