#!/usr/bin/env bash

total=0
dest="$(mktemp -d)"

desired_releases="edge v2.4 v2.5 v2.6 v2.7 v3.0 v3.1 v3.2 v3.3 v3.4 v3.5 v3.6 v3.7 v3.8"
for dir in $desired_releases; do
    echo "Calculating size for release $dir"
    old_total="$total"
    src="rsync://rsync.alpinelinux.org/alpine/$dir/"
    size=`rsync -a -n --stats "$src" "$dest" | grep '^Total file size' | tr -d ',' | awk '{ print $4 }'`
    total=$(($old_total + $size))
    echo "$dir: $size" | awk '{ print $1 sprintf("%.1f", $2/1073741824) }'
done

echo "total: $total" | awk '{ print $1 sprintf("%.1f", $2/1073741824) }'
rm -r "$dest"

