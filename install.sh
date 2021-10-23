#!/usr/bin/bash
DIRPATH=`pwd`
# check network
function CheckNet(){
    ping www.baidu.com -t 2 1>/dev/null 2>&1
    if [ $? != 0 ]
    then
        echo "Network is not ready, please connect it first"
        exit 0
    fi
}

# set ntp-time 
function SetNtp(){
    timedatectl set-ntp true
}

# set disk partition
function SetDiskPartition(){
    # check disk
    fdisk -l 2>/dev/null | grep "^Disk /dev/[shv]d[a-z]" | awk -F ',' '{print NR,$1}' > ${DIRPATH}/disk_list
    DISK_COUNT=$(cat ${DIRPATH}/disk_list | wc -l)
    if [ ${DISK_COUNT} = 0]
    then
        echo "Disk is not founded,please check it first"
        exit 0
    fi
    
    # choose disk
    cat ${DIRPATH}/disk_list
    echo "WARNING: DATA WILL BE CLEAN !!!"
    echo "Please choose a disk: "
    TRY_COUNT=3
    while true
    do
        read CHOOSENUM
        cat ${DIRPATH}/disk_list >/dev/null 2>&1
        if [ $? = 0 ]
        then
            DISK=$(cat ${DIRPATH}/disk_list | grep "^${CHOOSENUM}" | awk -F ':' '{print $1}' | awk '{print $3}')
            break
        else
            let "TRY_COUNT++"
            if [ ${TRY_COUNT} >0 ]
            then
                echo "Please enter a right number: "
            else
                echo "Please check you computer disk"
                exit 0
            fi
        fi
    done

    # clean disk
    echo -e "d\n\nd\n\nd\n\nd\n\nw\n" | fdisk ${DISK} > /dev/null 2>&1

    # create partition
    echo -e "n\n\n\n+300M\nt\n1\nn\n\n\nw\n" | fdisk ${DISK} > /dev/null 2>&1

    # format partition
    mkfs.fat -F32 ${DISK}1
    mkfs -t ext4 ${DISK}2

    # mount partition
    mount ${DISK}2 /mnt
    mkdir /mnt/EFI
    mount ${DISK}1 /mnt/EFI
}

# set pacman mirror
function SetMirror(){
    curl -X GET "https://archlinux.org/mirrorlist/?country=CN&protocol=https&ip_version=4&use_mirror_status=on" > /etc/pacman.d/mirrorlist
}



