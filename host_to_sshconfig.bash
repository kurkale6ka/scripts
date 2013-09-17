#! /usr/bin/env bash

# This script will add a host to my ssh config file and link it in ~/bin -> mssh
# Usage: 1. madd-host {host} {ip} or
#        2. madd-host {file}

mkhost() {
   ln -s "$HOME"/bin/{mssh,"$1"}

   if ! command grep -qi "$1" "$HOME"/.ssh/config; then
      printf 'host %s\n   hostname %s\n' "$1" "$2" >> "$HOME"/.ssh/config
      # printf '%s %s\n' "$2" "$1" >> "$HOME"/.hosts
      # sudo bash -c 'printf '%s %s\n' "$2" "$1" >> /etc/hosts' "$0" "$@"
   else
      return 1
   fi
}

# 1. Adding a single host
if (($# == 2)); then

   if mkhost "$1" "$2"
   then gvim -vc 'silent $' "$HOME"/.ssh/config
   fi
   #      gvim -vc 'silent bufdo$' "$HOME"/.{ssh/config,hosts}
   # sudo gvim -vc 'silent bufdo$' /etc/hosts

# 2. Reading a file with 'host ip' entries
# todo: read in an array in order to avoid multiple greps, lns ...?
elif (($# == 1)); then

   unset added
   while read -r host ip; do
      if [[ $host != \#* ]]; then
         mkhost "$host" "$ip" && added=true
      fi
   done < "$1"

   # edit ssh config's last line
   if [[ $added ]]
   then gvim -vc 'silent $' "$HOME"/.ssh/config
   fi
   #      gvim -vc 'silent bufdo$' "$HOME"/.{ssh/config,hosts}
   # sudo gvim -vc 'silent bufdo$' /etc/hosts
fi
