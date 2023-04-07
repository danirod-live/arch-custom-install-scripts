#!/bin/sh

set -e
cd "$(dirname $0)"

PART_ROOT=/dev/vda2
PART_UEFI=/dev/vda1
PART_SWAP=/dev/vda3

# Format
mkfs.ext4 $PART_ROOT
mkfs.fat -F32 $PART_UEFI
mkswap $PART_SWAP

# Mount
mount $PART_ROOT /mnt
mount $PART_UEFI /mnt/boot/efi --mkdir
swapon $PART_SWAP

# pacstrap
sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
pacstrap -K /mnt base base-devel linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

# Invoke second step inside arch-chroot
cp step2.sh step3.sh /mnt
arch-chroot /mnt /step2.sh
rm /mnt/step2.sh

echo "Ready, please reboot the computer to continue"
