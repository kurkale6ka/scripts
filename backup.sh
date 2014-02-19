#! /usr/bin/env bash

# Usage: backup.sh /path/to/backup/folder
# NB: /path/to/backup/folder must be excluded (ex: /mnt, /media...)

(($# == 1)) && [[ -d $1 ]] || {
   echo 'Usage: backup.sh /path/to/backup/folder'
   exit 1
}

# Archive, ACLs and extended attributes
rsync -aAX --stats --progress /* "$1"                \
--exclude=/dev/*                                     \
--exclude=/home/*/.cache/*                           \
--exclude=/home/*/.gvfs                              \
--exclude=/home/*/.local/share/Trash                 \
--exclude=/home/*/.mozilla/firefox/*.default/Cache/* \
--exclude=/home/*/.thumbnails/*                      \
--exclude=/lib/modules/*/volatile/.mounted           \
--exclude=/lost+found                                \
--exclude=/media/*                                   \
--exclude=/mnt/*                                     \
--exclude=/proc/*                                    \
--exclude=/run/*                                     \
--exclude=/sys/*                                     \
--exclude=/tmp/*                                     \
--exclude=/var/lib/pacman/sync/*                     \
--exclude=/var/lock/*                                \
--exclude=/var/log/journal/*                         \
--exclude=/var/run/*
