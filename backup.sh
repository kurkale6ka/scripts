#! /usr/bin/env bash

# NB: /path/to/backup/folder must be excluded (ex: /mnt, /media...)

# Archive, ACLs and extended attributes
rsync -aAX /* /path/to/backup/folder \
--exclude={\
/dev/*,\
/home/*/.cache/chromium/*,\
/home/*/.mozilla/firefox/*.default/Cache/*,\
/home/*/.thumbnails/*,\
/lost+found,\
/media/*,\
/mnt/*,\
/proc/*,\
/run/*,\
/sys/*,\
/tmp/*,\
/var/lib/pacman/sync/*,\
/var/log/journal/*\
}
