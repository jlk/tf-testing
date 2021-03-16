#!/usr/bin/sh

# Script to mirror alpine package repository for specified releases
# Based on https://wiki.alpinelinux.org/wiki/How_to_setup_a_Alpine_Linux_mirror

SRC=rsync://rsync.alpinelinux.org/alpine/ 
DEST=/var/www/html/alpine/

# Make sure we never run 2 rsync at the same time
# (this doesn't work on OSX)
lockfile="/tmp/alpine-mirror.lock"
if [ -z "$flock" ] ; then
  exec env flock=1 flock -n $lockfile "$0" "$@"
fi

EXCLUDES=""
# Uncomment this to exclude old v2.x branches
#EXCLUDES="v2.*"
#
# Or maybe you just want the supported releases (space between each)
# EXCLUDES="v2.* edge v3.0 v3.1 v3.2 v3.3 v3.4 v3.5"

EXCLUDE=""
for excluded in $EXCLUDES; do
    EXCLUDE="$EXCLUDE --exclude $excluded"
done

mkdir -p "$DEST"
/usr/bin/rsync \
        --archive \
        --update \
        --hard-links \
        --delete \
        --delete-after \
        --delay-updates \
        --timeout=600 \
        $EXCLUDE \
        "$SRC" "$DEST"

