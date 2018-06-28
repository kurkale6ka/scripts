#! /usr/bin/env bash

# Generate a postfix Makefile for Berkeley DB files (.db)
#
# http://www.postfix.org/DATABASE_README.html#safe_db

shopt -s extglob

cd /etc/postfix || exit 1

# array of already created .db files, bar aliases.db
dbs=(!(aliases).db)

## databases target + all prerequisites
printf 'databases: aliases.db \\\n' > Makefile

for ((i = 0; i < ${#dbs[@]} - 1; i++))
do
   printf '%s \\\n' "${dbs[$i]}" >> Makefile
done

# don't append \ to the last one
printf '%s\n' "${dbs[${#dbs[@]}-1]}" >> Makefile

## Rules
cat >> Makefile << ALIASES

aliases.db: aliases.in
	@echo updating "aliases.db"...
	@postalias "aliases.in"
	@mv "aliases.in.db" "aliases.db"

ALIASES

for i in "${dbs[@]}"
do
   # create link
   # ex: aliases.in -> aliases
   ln -sf "${i%.db}" "${i%.db}".in

   # rule
   {
      printf '%s: %s.in\n' "$i" "${i%.db}"
      printf '\t@echo updating "%s"...\n' "$i"
      printf '\t@postmap "%s.in"\n' "${i%.db}"
      printf '\t@mv "%s.in.db" "%s"\n\n' "${i%.db}" "$i"
   } >> Makefile
done

## Get rid of extra newline
if command -v ed >/dev/null 2>&1
then
   printf '%s\n' H '$d' wq | ed -s Makefile
elif [[ ! -L Makefile ]]
then
   sed -i '$d' Makefile
fi
