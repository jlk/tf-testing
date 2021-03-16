#!/bin/sh

# rsync job
mv /home/centos/provisioning-scripts/rsync-alpine-repo.sh /etc/cron.daily
chown root:root /etc/cron.daily/rsync-alpine-repo.sh

