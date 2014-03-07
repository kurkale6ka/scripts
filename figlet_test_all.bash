#! /usr/bin/env bash

command -v figlet || exit 1

                                     figlet             "${1:-Intel i7 4770k}"
printf "\nfiglet -f slant:    \n" && figlet -f slant    "${1:-Intel i7 4770k}"
printf "\nfiglet -f smslant:  \n" && figlet -f smslant  "${1:-Intel i7 4770k}"
printf "\nfiglet -f small:    \n" && figlet -f small    "${1:-Intel i7 4770k}"
printf "\nfiglet -f block:    \n" && figlet -f block    "${1:-Intel i7 4770k}"
printf "\nfiglet -f lean:     \n" && figlet -f lean     "${1:-Intel i7 4770k}"
printf "\nfiglet -f lean:     \n" && figlet -f lean     "${1:-Intel i7 4770k}" | tr ' _/' ' ()'
printf "\nfiglet -f mini:     \n" && figlet -f mini     "${1:-Intel i7 4770k}"
printf "\nfiglet -f digital:\n\n" && figlet -f digital  "${1:-Intel i7 4770k}"
printf "\nfiglet -f bubble:   \n" && figlet -f bubble   "${1:-Intel i7 4770k}"
printf "\nfiglet -f script:   \n" && figlet -f script   "${1:-Intel i7 4770k}"
printf "\nfiglet -f smscript: \n" && figlet -f smscript "${1:-Intel i7 4770k}"
printf "\nfiglet -f banner: \n\n" && figlet -f banner   "${1:-Intel i7 4770k}"
printf "\nfiglet -f ivrit:    \n" && figlet -f ivrit    "${1:-Intel i7 4770k}"
