#!/bin/sh

PARTITION=xvdb
MOUNTPOINT=/var/www/html

yum -y update

lsblk -f | grep $PARTITION | grep xfs

if [ $? -eq 1 ] ; then
  echo Data volume not yet formatted. Doing so now.
  mkfs -t xfs -L alpinemirror /dev/$PARTITION
else
  echo Data volume already formatted.
fi

grep $MOUNTPOINT /etc/fstab
if [ $? -eq 1 ] ; then
  echo Data volume not yet mounted. Setting that up...
  mkdir -p $MOUNTPOINT
  echo "LABEL=alpinemirror $MOUNTPOINT                       xfs     defaults        0 0" >> /etc/fstab
  mount -a
fi

yum -y install httpd
echo > /var/www/html/index.html
systemctl enable httpd
systemctl start httpd

