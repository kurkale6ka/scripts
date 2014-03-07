#! /usr/bin/env bash

command -v figlet || exit 1

                                     figlet             "${1:-ASUS Z87-PRO}"
printf "\nfiglet -f slant:    \n" && figlet -f slant    "${1:-ASUS Z87-PRO}"
printf "\nfiglet -f smslant:  \n" && figlet -f smslant  "${1:-ASUS Z87-PRO}"
printf "\nfiglet -f small:    \n" && figlet -f small    "${1:-ASUS Z87-PRO}"
printf "\nfiglet -f block:    \n" && figlet -f block    "${1:-ASUS Z87-PRO}"
printf "\nfiglet -f lean:     \n" && figlet -f lean     "${1:-ASUS Z87-PRO}"
printf "\nfiglet -f lean:     \n" && figlet -f lean     "${1:-ASUS Z87-PRO}" | tr ' _/' ' ()'
printf "\nfiglet -f mini:     \n" && figlet -f mini     "${1:-ASUS Z87-PRO}"
printf "\nfiglet -f digital:\n\n" && figlet -f digital  "${1:-ASUS Z87-PRO}"
printf "\nfiglet -f bubble:   \n" && figlet -f bubble   "${1:-ASUS Z87-PRO}"
printf "\nfiglet -f script:   \n" && figlet -f script   "${1:-ASUS Z87-PRO}"
printf "\nfiglet -f smscript: \n" && figlet -f smscript "${1:-ASUS Z87-PRO}"
printf "\nfiglet -f banner: \n\n" && figlet -f banner   "${1:-ASUS Z87-PRO}"
printf "\nfiglet -f ivrit:    \n" && figlet -f ivrit    "${1:-ASUS Z87-PRO}"
