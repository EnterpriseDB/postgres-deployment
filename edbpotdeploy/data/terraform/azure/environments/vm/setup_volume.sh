#!/bin/bash

COUNTER=0
DEVICE=$1
MOUNTPOINT=$2

while [ ! -b ${DEVICE} ]; do
    sleep 2
    COUNTER=$((COUNTER + 1))
    if [ $COUNTER -ge 10 ]; then
        exit 2
    fi
done


sudo mkfs.xfs "${DEVICE}"
sudo mkdir -p "${MOUNTPOINT}"
DEVICE_UUID="$(sudo /sbin/wipefs -i -O UUID ${DEVICE})"
sudo mount -t xfs ${DEVICE} ${MOUNTPOINT}
echo "UUID=${DEVICE_UUID} ${MOUNTPOINT} xfs noatime 0 0" | sudo tee -a /etc/fstab
