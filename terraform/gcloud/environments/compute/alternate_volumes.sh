#!/bin/bash
set -euxo pipefail

# /sdb
MNT_DIR=/pgdata

if [[ -d "$MNT_DIR" ]]; then
   exit
else
   sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb; \
   sudo mkdir -p $MNT_DIR
   sudo mount -o discard,defaults /dev/sdb $MNT_DIR

   # Add fstab entry
   echo UUID=`sudo blkid -s UUID -o value /dev/sdb` $MNT_DIR ext4 discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab
fi

# /sdc
MNT_DIR=/pgwal

if [[ -d "$MNT_DIR" ]]; then
   exit
else
   sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdc; \
   sudo mkdir -p $MNT_DIR
   sudo mount -o discard,defaults /dev/sdc $MNT_DIR

   # Add fstab entry
   echo UUID=`sudo blkid -s UUID -o value /dev/sdc` $MNT_DIR ext4 discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab
fi

# /sdd
MNT_DIR=/pgtblspc1

if [[ -d "$MNT_DIR" ]]; then
   exit
else
   sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdd; \
   sudo mkdir -p $MNT_DIR
   sudo mount -o discard,defaults /dev/sdd $MNT_DIR

   # Add fstab entry
   echo UUID=`sudo blkid -s UUID -o value /dev/sdd` $MNT_DIR ext4 discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab
fi

# /sde
MNT_DIR=/pgtblspc2

if [[ -d "$MNT_DIR" ]]; then
   exit
else
   sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sde; \
   sudo mkdir -p $MNT_DIR
   sudo mount -o discard,defaults /dev/sde $MNT_DIR

   # Add fstab entry
   echo UUID=`sudo blkid -s UUID -o value /dev/sde` $MNT_DIR ext4 discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab
fi

# /sdf
MNT_DIR=/pgtblspc3

if [[ -d "$MNT_DIR" ]]; then
   exit
else
   sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdf; \
   sudo mkdir -p $MNT_DIR
   sudo mount -o discard,defaults /dev/sdf $MNT_DIR

   # Add fstab entry
   echo UUID=`sudo blkid -s UUID -o value /dev/sdf` $MNT_DIR ext4 discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab
fi
