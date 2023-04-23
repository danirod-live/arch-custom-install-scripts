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
	cat >/mnt/tmp.install <<EOFMAIN
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc

sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo KEYMAP=es > /etc/vconsole.conf

sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf

echo archvm.local > /etc/hostname
systemctl enable systemd-networkd
systemctl enable systemd-resolved
cat <<EOF >/etc/systemd/network/wired.network
[Match]
Name=enp1s0

[Network]
DHCP=yes
EOF

# SSH server
pacman -S openssh --noconfirm
systemctl enable sshd

# GRUB
pacman -S grub efibootmgr --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Set the root password
echo "Please type root password now:"
passwd

# Create user
pacman -S sudo --noconfirm
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
echo "Defaults lecture=never" >> /etc/sudoers
useradd -m -G sys,network,users,video,storage,lp,input,audio,wheel -s /bin/bash danirod
echo "Type the password for danirod:"
passwd danirod
EOFMAIN
chmod +x /mnt/tmp.install
arch-chroot /mnt /tmp.install
rm /mnt/tmp.install
}

third_stage_script() {
echo "* Running third stage configuration..."
cat >/mnt/tmp.install <<EOFMAIN
pacman -Sy --noconfirm git stow tmux vim gnupg fzf \
bat ripgrep diff-so-fancy tig rsync ranger w3m newsboat \
net-tools man-db man-pages

git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
chown -R nobody:nobody /tmp/yay-bin
pushd /tmp/yay-bin
sudo -u nobody makepkg
pacman --noconfirm -U /tmp/yay-bin/*.tar.zst
popd

rm -f /home/danirod/.bash*
sudo -u danirod git clone https://github.com/danirod/dotfiles /home/danirod/.dotfiles
sudo -u danirod git clone https://github.com/danirod/vimrc /home/danirod/.vim
sudo -u danirod git -C /home/danirod/.dotfiles submodule init
sudo -u danirod git -C /home/danirod/.dotfiles submodule update
sudo -u danirod git -C /home/danirod/.vim submodule init
sudo -u danirod git -C /home/danirod/.vim submodule update
sudo -u danirod stow -d /home/danirod/.dotfiles/ home
EOFMAIN
	chmod +x /mnt/tmp.install
	arch-chroot /mnt /tmp.install
	rm /mnt/tmp.install
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
