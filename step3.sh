#!/bin/sh

cd "$(dirname $0)"
set -e

# Install some programs
pacman -Sy --noconfirm git stow tmux vim gnupg fzf \
	bat ripgrep diff-so-fancy tig rsync ranger w3m newsboat \
	net-tools man-db man-pages

# Install yay
git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
chown -R nobody:nobody /tmp/yay-bin
pushd /tmp/yay-bin
sudo -u nobody makepkg
pacman --noconfirm -U /tmp/yay-bin/*.tar.zst
popd

# Install dotfiles
rm -f /home/danirod/.bash*
sudo -u danirod git clone https://github.com/danirod/dotfiles /home/danirod/.dotfiles
sudo -u danirod git clone https://github.com/danirod/vimrc /home/danirod/.vim
sudo -u danirod git -C /home/danirod/.dotfiles submodule init
sudo -u danirod git -C /home/danirod/.dotfiles submodule update
sudo -u danirod git -C /home/danirod/.vim submodule init
sudo -u danirod git -C /home/danirod/.vim submodule update
sudo -u danirod stow -d /home/danirod/.dotfiles/ home
