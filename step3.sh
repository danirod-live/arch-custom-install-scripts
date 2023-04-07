#!/bin/sh

cd "$(dirname $0)"
set -e

# Install some programs
sudo pacman -Sy --noconfirm git stow tmux vim gnupg fzf \
	bat ripgrep diff-so-fancy tig rsync ranger w3m newsboat \
	net-tools man-db man-pages

# Install dotfiles
git clone https://github.com/danirod/dotfiles .dotfiles
git clone https://github.com/danirod/vimrc .vim
git -C .dotfiles submodule init
git -C .dotfiles submodule update
git -C .vim submodule init
git -C .vim submodule update
rm .bash*
(cd .dotfiles && stow home)
(cd .dotfiles && stow i3)

# Install yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -srci --noconfirm
cd ..
rm -rf yay

