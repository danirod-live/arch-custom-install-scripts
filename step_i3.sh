#!/bin/sh

yay -S --cleanafter --batchinstall --noconfirm \
	--nocleanmenu --nodiffmenu --removemake \
	xorg-server xf86-video-vesa i3-wm \
	i3lock-fancy-multimonitor alacritty \
	picom polybar rofi hsetroot dunst \
  ttf-ubuntu-font-family ttf-icomoon-feather \
	ttf-dejavu ttf-liberation noto-fonts \
	nordzy-icon-theme xcursor-openzone \
	xorg-xinit xinit-xsession sddm pulseaudio \
	archlinux-themes-sddm firefox jack2 \
	noto-fonts

sudo localectl set-x11-keymap es
systemctl enable --user pulseaudio
sudo systemctl enable sddm

sudo mkdir -p /etc/sddm.conf.d
cat <<EOF | sudo tee /etc/sddm.conf.d/theme.conf
[Theme]
Current=archlinux-simplyblack
CursorTheme=OpenZone_White
EOF
