#!/bin/bash
for i in {b..f}
do
    DEVNAME="sd${i}"
    case "${i}" in
      b)
        VOLNAME="pgdata"
        ;;
      c)
        VOLNAME="pgwal"
        ;;
      d)
        CURRVOL="1"
        VOLNAME="pgtblspc${CURRVOL}"
        ;;
      e)
        CURRVOL="2"
        VOLNAME="pgtblspc${CURRVOL}"
        ;;
      f)
        CURRVOL="3"
        VOLNAME="pgtblspc${CURRVOL}"
        ;;
    esac
    CMD=$(sudo lsblk | sudo grep "${DEVNAME}" | wc -l)
    if [[ "${CMD}" > 0 ]]
    then
        sudo mkfs -F -t ext4 "/dev/${DEVNAME}"
        sudo mkdir "/${VOLNAME}"
        sudo mount -t ext4 "/dev/${DEVNAME}" "/${VOLNAME}"
        CMD=$(sudo grep "${DEVNAME}" /etc/fstab | wc -l)
        if [[ "${CMD}" < 1 ]]
        then
            echo "/dev/${DEVNAME} /${VOLNAME} auto noatime 0 0" | sudo tee -a /etc/fstab
        fi
        sleep 5
    fi
done
sudo mount -a