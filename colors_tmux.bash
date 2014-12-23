#! /usr/bin/env bash

esc='\x1b[38;5;%sm'

for i in {0..42}
do
   printf "$esc%-9s $esc%-9s $esc%-10s $esc%-11s" "$i"          color"$i"          \
                                                  "$((i+43))"   color"$((i+43))"   \
                                                  "$((i+43*2))" color"$((i+43*2))" \
                                                  "$((i+43*3))" color"$((i+43*3))"
   if ((i+43*5 < 256))
   then
      printf "$esc%-10s $esc%-11s\n" "$((i+43*4))" color"$((i+43*4))" \
                                     "$((i+43*5))" color"$((i+43*5))"
   else
      printf "$esc%-10s\n" "$((i+43*4))" color"$((i+43*4))"
   fi
done

tput sgr0
