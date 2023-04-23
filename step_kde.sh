#!/bin/sh

# Install KDE
sudo pacman -S --noconfirm plasma kde-applications firefox
sudo systemctl enable sddm.service

# Clean the cache
yes | pacman -Scc
