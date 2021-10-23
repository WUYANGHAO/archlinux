#!/usr/bin/bash

# after connect to network

# set time
timedatectl set-ntp true

# set disk
DISK=$(fdisk -l 2>/dev/null | grep "^Disk /dev/[shv]d[a-z]" | cut -c6-13 | head -1)
echo -e "n\np\n1"
