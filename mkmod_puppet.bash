#! /usr/bin/env bash

(($#)) || {
  echo 'Usage [-b /modules/directory] module'
  exit 1
}

if (($# > 1))
then module="${2%%/}"/"$3"
else module="$HOME"/.puppet/modules/"$1"
fi

code_folder=manifests

mkdir -p "$module"/{"$code_folder",files,lib,templates,tests}

main="$module"/"$code_folder"/init.pp

if [[ ! -f $main ]]; then
touch "$main"
ed -s "$main" << EOT
H
0i
class ${module##*/} {
}
.
wq
EOT
fi
