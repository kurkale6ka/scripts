#! /usr/bin/env bash

# Check a csv file
#
# report any rows with a wrong number of fields:
# + ln: xx,xx,xx,xx,xx -> too many fields
# - ln: xx,xx,xx       -> too few  fields
#
# Usage: csv_fields_check.bash {document.csv}

# get the most often occurring number of fields
nf="$(awk -F, '{print NF}' "$1" | sort | uniq -c | sort -rn | head -n1 | awk '{print $2}')"

awk -F,  "NF>$nf"' {print "+ "NR": "$0}
        '"NF<$nf"' {print "- "NR": "$0}' "$1"
