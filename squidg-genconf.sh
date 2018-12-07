#! /usr/bin/env bash

# Generate squidGuard.conf from a blacklist directory tree
#
# create .db files with:
#    squidGuard -db -c squidGuard.conf -C all
# test with:
#    echo "http://www.twitter.com - - - GET" | squidGuard -c squidGuard.conf -d 2>&1 | grep block

# tar zxvf blacklist.tgz --strip 1, in dbhome
dbhome=/var/db/squidGuard
logdir=/var/log/squidGuard

cd "$dbhome" || exit 1

cfg=squidGuard.conf

cat > "$cfg" << SETTINGS
dbhome $dbhome
logdir $logdir

SETTINGS

acl=()

# Loop over all folders in the blacklist directory tree
while IFS= read -r -d $'\0'
do
   if [[ -f $REPLY/domains || -f $REPLY/urls ]]
   then
      acl+=("$REPLY")

      {
         # define dest 'category' blocks
         echo "dest ${REPLY//\//_} {"
            [[ -f $REPLY/domains ]] && echo "   domainlist $REPLY/domains"
            [[ -f $REPLY/urls    ]] && echo "   urllist $REPLY/urls"
            echo '   log block.log'
         echo '}'
         echo
      } >> "$cfg"
   fi
done < <(find . -type d -printf "%P\0")

# Write the ACLs
cat >> "$cfg" << ACL
acl  {
   default  {
      pass ${acl[@]//\//_} all
      redirect http://localhost/block
      log block.log
   }
}
ACL
