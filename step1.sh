#!/bin/sh

set -e
cd "$(dirname $0)"

error=""
if [ -z "$PART_ROOT" ]; then
	echo "Error: PART_ROOT variable is not set (maybe /dev/sda2?)"
	error=1
fi
if [ -z "$PART_UEFI" ]; then
	echo "Error: PART_UEFI variable is not set (maybe /dev/sda1?)"
	error=1
fi
if [ -z "$PART_SWAP" ]; then
	echo "Error: PART_SWAP variable is not set (maybe /dev/sda3?)"
fi
if [ -n "$error" ]; then
	echo "Aborting due to previous errors"
	exit 1
fi

# Now that the checking is done, make sure that environment variables are there.
set -o nounset

format_partitions() {
	echo "* Formatting system partitions..."
	mkfs.ext4 $PART_ROOT
	mkfs.fat -F32 $PART_UEFI
	mkswap $PART_SWAP
}

mount_partitions() {
	echo "* Mounting system partitions..."
	mount $PART_ROOT /mnt
	mount $PART_UEFI /mnt/boot/efi --mkdir
	swapon $PART_SWAP
}

configure_pacstrap() {
	echo "* Configuring pacstrap..."
	sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
	sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
}

bootstrap_system() {
	echo "* Bootstrapping the system..."
	pacstrap -K /mnt base base-devel linux linux-firmware
	genfstab -U /mnt >> /mnt/etc/fstab
}

second_stage_script() {
	echo "* Running second stage configuration..."
	cp step2.sh /mnt
	arch-chroot /mnt /step2.sh
	rm /mnt/step2.sh
}

third_stage_script() {
	echo "* Running third stage configuration..."
	cp step3.sh /mnt
	arch-chroot /mnt /step3.sh
	rm /mnt/step3.sh
}

cleanup() {
	echo "* Cleaning up the cache..."
	yes | arch-chroot /mnt pacman -Scc
}

format_partitions
mount_partitions
configure_pacstrap
bootstrap_system
second_stage_script
third_stage_script
cleanup

echo
echo "The computer is ready to rock"
