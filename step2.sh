#!/bin/sh

set -e
cd "$(dirname $0)"

# Configure time
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc

# Configure locale
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo KEYMAP=es > /etc/vconsole.conf

# Configure pacman
sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf

# Network
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
