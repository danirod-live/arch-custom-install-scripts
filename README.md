## Ideas

* PKGBUILD to install my desktop settings (`pacman -S danirod-desktop-i3`) -- not in AUR, is internal for me
* Build server, local repository

# TODO: update README (ironic)

## Virtual machine spawning

The install.sh script will spawn a UEFI machine, so make sure to follow the UEFI procedure if you lookup online.

The uninstall.sh script will remove the previously created machine with install.sh.

They both use libvirt and QEMU/KVM if available. Remember to start the network beforehand.

## SSH server

Encouraged to spawn an SSH server as soon as the installation boots. `passwd` and then you can `ssh root@archiso`

## Installation commands

### Arch Linux installation

* `fdisk /dev/vda`
  - `g` to create a GPT table
	- `n 1 <Enter> +512M` + `t 1 uefi` to create the ESP
	- `n 2 <Enter> -1G` + `t 2 linux` to create a standard root
	- `n 3 <Enter> <Enter>` + `t 3 swap` to create a swap
	- `p` to verify
	- `w` to write and exit
* Format:
  - `mkfs.fat -F32 /dev/vda1`
	- `mkfs.ext4 /dev/vda2`
	- `mkswap /dev/vda3`
* Mount:
  - `mount /dev/vda2 /mnt`
	- `mount --mkdir /dev/vda1 /mnt/boot/efi`
	- `swapon /dev/vda3`
* System install
  - `pacstrap -K /mnt base base-devel linux linux-firmware`
	- `genfstab -U /mnt >> /mnt/etc/fstab`
* System configuration
	- `arch-chroot /mnt`
	- `ln -sf /usr/share/zoneinfo/Region/City /etc/localtime`
	- `hwclock --systohc`
	- `sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen`
	- `locale-gen`
	- `echo LANG=en_US.UTF-8 > /etc/locale.conf`
	- `echo KEYMAP=en > /etc/vconsole.conf`
	- `mkinitcpio -P`
  - `passwd`
* Network
	- `echo archvm.local > /etc/hostname`
	- `systemctl enable systemd-networkd`
	- `systemctl enable systemd-resolved`
	- systemd-wired.network → /etc/systemd/network/wired.network
* SSH server
  - `pacman -S openssh`
	- `systemctl enable sshd`
* GRUB (in my host machine there will also be a refind installation to handoff to GRUB, FreeBSD or Windows depending on the day)
	- `pacman -S grub efibootmgr`
	- `grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB`
	- `grub-mkconfig -o /boot/grub/grub.cfg`
* User creation
  - `pacman -S sudo`
	- `echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers`
	- `echo "Defaults lecture=never" >> /etc/sudoers`
	- `visudo` and allow the wheel group
	- `useradd -m -G sys,network,users,video,storage,lp,input,audio,wheel -s /bin/bash danirod`
	- `passwd danirod`
* reboot

### Post configuration

* yay (makepkg refuses to do this as root, do it once installed)
  - `sudo pacman -S git`
	- `git clone https://aur.archlinux.org/yay.git`
	- `cd yay`
	- `makepkg -sci`
	- `cd ..`
	- `rm -rf yay`
* dotfiles
  - `sudo pacman -S stow tmux`
  - `git clone https://github.com/danirod/dotfiles .dotfiles`
  - `rm .bash*`
  - `cd .dotfiles`
	- `git submodule init`
	- `git submodule update`
  - `stow home`
  - `stow i3`
	- `cd ..`
	- `tmux` and press `Ctrl-A Shift-I` and leave tmux
* vim
  - `sudo pacman -S vim`
  - `git clone https://github.com/danirod/vimrc .vim`
	- `cd .vim`
	- `git submodule init`
	- `git submodule update`
* More packages to install
	- gnupg
	- fzf
	- bat
	- ripgrep
	- diff-so-fancy
	- tig
	- rsync
	- ranger
	- w3m
	- newsboat
	- net-tools
	- man-db
	- man-pages
	- gnome-keyring

### Packages required to boot the system interface

* X11 server (required for i3):
  - xorg-server
	- xf86-video-vesa (or whatever)
* Desktop shell
  - i3-wm
	- i3lock-fancy-multimonitor
	- alacritty
	- picom
	- polybar
	- rofi
	- hsetroot
	- dunst
* Fonts
  - ttf-ubuntu-font-family
	- ttf-icomoon-feather
	- ttf-dejavu
	- ttf-liberation
	- noto-fonts
* Icon themes and cursors
  - nordzy-icon-theme-git
	- xcursor-openzone
* Login manager (personal preference is sddm reading my .xinitrc)
	- xorg-xinit
	- xinit-xsession
	- sddm
	- archlinux-themes-sddm
* GUI apps
  - thunar
  - firefox
		- jack2 (prevent installation of full pipewire)

### Other configurations

* X11 locale
  - `sudo localectl set-x11-keymap es`
* Enable services
  - systemctl enable --user pulseaudio

### SDDM configuration

* sudo systemctl enable sddm
* sddm-theme.conf in the /etc/sddm.conf.d/theme.conf

