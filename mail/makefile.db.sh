#! /usr/bin/env bash

# Generate a postfix Makefile for Berkeley DB files (.db)
#
# http://www.postfix.org/DATABASE_README.html#safe_db

cd /etc/postfix || exit 1

shopt -s extglob nullglob

# array of already created .db files, bar aliases.db
dbs=(!(aliases).db)

# checks
if [[ -f aliases.db || -n $dbs ]]
then
   echo 'Creating rules for:'
else
   echo 'No .db files found. Exiting.' 1>&2
   exit 2
fi

# list created rules
if [[ -f aliases.db ]]
then
   echo '* aliases.db'
fi

if [[ -n $dbs ]]
then
   printf '* %s\n' "${dbs[@]}"
fi

## databases target + all prerequisites
echo -n 'databases: ' > Makefile

if [[ -f aliases.db ]]
then
   if [[ -z $dbs ]]
   then
      echo 'aliases.db' >> Makefile
   else
      echo 'aliases.db \' >> Makefile
   fi
fi

if [[ -n $dbs ]]
then
   for ((i = 0; i < ${#dbs[@]} - 1; i++))
   do
      printf '%s \\\n' "${dbs[$i]}" >> Makefile
   done

   # don't append \ to the last one
   printf '%s\n' "${dbs[${#dbs[@]}-1]}" >> Makefile
fi

## Rules
echo >> Makefile

if [[ -f aliases.db ]]
then
ln -sf aliases aliases.in

cat >> Makefile << ALIASES
aliases.db: aliases.in
	@echo updating "aliases.db"...
	@postalias "aliases.in"
	@mv "aliases.in.db" "aliases.db"

ALIASES
fi

if [[ -n $dbs ]]
then
   for i in "${dbs[@]}"
   do
      # create link
      # ex: canonical.in -> canonical
      ln -sf "${i%.db}" "${i%.db}".in

      # rule
      {
         printf '%s: %s.in\n' "$i" "${i%.db}"
         printf '\t@echo updating "%s"...\n' "$i"
         printf '\t@postmap "%s.in"\n' "${i%.db}"
         printf '\t@mv "%s.in.db" "%s"\n\n' "${i%.db}" "$i"
      } >> Makefile
   done
fi

## Get rid of extra newline
if command -v ed >/dev/null 2>&1
then
   printf '%s\n' H '$d' wq | ed -s Makefile
elif [[ ! -L Makefile ]]
then
   sed -i '$d' Makefile
fi
