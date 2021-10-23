#!/usr/bin/bash
DIRPATH=`pwd`

# check network
function CheckNet(){
    ping www.baidu.com -c 2 1>/dev/null 2>&1
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
function SetDisk(){
    # clean mount
    df -h | grep "/mnt"
    if [ $? = 0 ]
    then
        umount -R /mnt
    fi

    # check disk
    fdisk -l 2>/dev/null | grep "^Disk /dev/[shv]d[a-z]" | awk -F ',' '{print NR,$1}' > ${DIRPATH}/disk_list
    DISK_COUNT=$(cat ${DIRPATH}/disk_list | wc -l)
    if [ ${DISK_COUNT} = 0 ]
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
        cat ${DIRPATH}/disk_list | grep "^${CHOOSENUM}"
        if [ $? = 0 ]
        then
            DISK=$(cat ${DIRPATH}/disk_list | grep "^${CHOOSENUM}" | awk -F ':' '{print $1}' | awk '{print $3}')
            break
        else
            let "TRY_COUNT--"
            if [ ${TRY_COUNT} -gt 0 ]
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
    echo -e "n\n\n\n+300M\nY\nt\n1\nn\n\n\n\nY\nw\n" | fdisk ${DISK} > /dev/null 2>&1

    # format partition
    mkfs.fat -F32 ${DISK}1
    echo -e "y\n" | mkfs -t ext4 ${DISK}2

    # mount partition
    mount -v ${DISK}2 /mnt
    mkdir -v /mnt/EFI
    mount -v ${DISK}1 /mnt/EFI
}

# set pacman mirror
function SetMirror(){
    curl -X GET "https://archlinux.org/mirrorlist/?country=CN&protocol=https&ip_version=4&use_mirror_status=on" > /etc/pacman.d/mirrorlist
    sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
}

# install base system
function InstallBase(){
    pacstrap /mnt base linux linux-firmware
    genfstab -U /mnt >> /mnt/etc/fstab
}

# config in chroot
function ConfigChroot(){
arch-chroot /mnt <<EOF
# set time none
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc

# set locale
sed -i "s/^#en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen
sed -i "s/^#zh_CN.UTF-8/zh_CN.UTF-8/g" /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# set hostname hosts
echo "MYARCH" > /etc/hostname
echo "127.0.0.1	localhost" >> /etc/hosts
echo "::1		localhost" >> /etc/hosts

# install require 
yes | pacman -S iwd networkmanager grub efibootmgr intel-ucode
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable NetworkManager
systemctl enable iwd
echo -e "[Match]\nName=wlan0\n[Network]\nDHCP=ipv4" > /etc/systemd/network/0-wireless.network
echo -e "[Match]\nName=eno1\n[Network]\nDHCP=ipv4" > /etc/systemd/network/0-wired.network
echo -e "root\nroot\n" | passwd root

# install bootleader
grub-install --target=x86_64-efi --efi-directory=/EFI --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# create user
useradd -m -G wheel -s /bin/bash "arch"
echo "LANG=zh_CN.UTF-8" > /home/arch/.config/locale.conf
echo -e "arch\narch\n" | passwd arch
yes | pacman -S sudo
sed -i "s/# %wheel  ALL=(ALL) ALL/%wheel  ALL=(ALL) ALL/g" /etc/sudoers

# install desktop
yes | pacman -S xf86-video-intel cups bluez gnome-software-packagekit-plugin bash-completion wqy-microhei opendesktop-fonts
echo -e "\n\n\n" | pacman -Sy gnome
systemctl enable gdm
systemctl enable cups
systemctl enable bluetooth
EOF
}

# reboot
function Reboot(){
    echo "Will reboot now"
    echo "use user 'arch' passwd 'arch' login system"
    umount -R /mnt
    reboot
}

# main
CheckNet
SetNtp
SetDisk
SetMirror
InstallBase
ConfigChroot
Reboot
