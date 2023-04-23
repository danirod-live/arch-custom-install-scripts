#!/bin/sh

# Install GNOME
sudo pacman -S --noconfirm gnome networkmanager

# Enable startup services.
sudo systemctl enable networkmanager.service
sudo systemctl enable gdm.service

# Clean the cache
yes | sudo pacman -Scc
