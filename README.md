# arch-custom-install-scripts

These are my custom install scripts for Arch Linux. I use them to reset my system or to deploy a new
Arch installation to a different machine. I also use them to create my virtual machines used to
record my content for some of my YouTube channels.

Please, note that these are mine. If they work for you, that's fine, but you'll probably need to tweak
them before use. This repository is a public backup.

## The scripts

* step1.sh: used in the arch-install phase, it bootstraps the partitions of an UEFI system installation.
* step2.sh: used in the arch-chroot phase, it installs the base system.
* step3.sh: used in the post-install phase (at the moment), it installs my dotfiles and base apps.
* Extra scripts: `step_i3.sh`... should set the window manager and other specific tweaks. As I need to
  deploy more virtual machines to record other kinds of videos, I'll probably have other install scripts
	(step_xfce, step_kde, step_gnome...).

### What do the scripts do

* They install Arch Linux.
* They install my config.
* They install a desktop environment.

### What I wish the scripts could do (TO-DO list)

* They could install BitWarden already.
* They could download my SSH key from my BitWarden account.
* They could download my GPG key from my BitWarden account.
* They could configure my GPG keys already.
* They could skip setting up a bootloader (for dualboot or tripleboot systems,
  I use refind in my computers anyway).

### What the scripts will not do

* They will not partition the drive (it should be done before starting the scripts).
* They will not reconfigure refind for you.

## The qcow2 factory

Powered by libvirt and QEMU, this makes easy to spin virtual machines with the scripts.

So my flow would be to eventually have a script that spins virtual machines using virt-install or
straight qemu commands. I'd keep a read-only QCOW2 hard drive that I'd duplicate so that I can
break a virtual machine safely.

However, the QCOW2 hard drive would eventually come out of date or maybe I could lose it, so
having the QCOW2 factory being able to generate brand new virtual hard drives using these scripts
is a nice to have.

### Grab Arch Linux ISO

Download the latest Arch Linux install CD and place it into archlinux.iso in this directory.

### diskctl

It can be used to manage the qcow2 files. By default, it will work with a virtual hard drive located
at archlinux.qcow2 file. This can be changed using the `TARGET_FILE` environment variable.

Commands:

* `./diskctl.sh create`. Creates a new preparitioned disk. It depends on
  qemu-nbd in order to mount the QCOW2 file into the system, so having
  `qemu-img` (or whoever provides qemu-nbd) and the nbd kernel module loaded
  are dependencies.
* `./diskctl.sh sparse`. Reclaims the free space in the virtual disk. It
  depends on virt-sparsify to do this, so `guestfs-tools` (or whoever provides
  virt-sparsify) is required as a dependency.

### Install the system

These steps depend on `virt-install` and `virsh` to work. SSH is required too.

The point is to start a new virtual machine using the created qcow2 hard drive and install Arch Linux
from the CD-ROM into the hard drive. The thing is that we need to copy things from the outside world
via SSH, so we need to set the password beforehand, which unfortunately is not set for the live
environment. This causes the number of steps to quickly grow.

TODO: And this is why I think that rolling a custom archiso would be quicker!

* `./bootstrap.sh create-vm` to create the virtual machine. It will exit to support headless.
* `./bootstrap.sh attach-vm` to attach to the virtual machine.
  * (Inside the VM) `passwd root` to se the password for root.
  * (Ctrl-C the terminal where you ran `./bootstrap.sh attach-vm` to disconnect)
* `./bootstrap.sh copy-base` to copy the install scripts. Type the password when needed.
* `./bootstrap.sh ssh` to SSH into the machine. Type the password when needed.
  * `PART_ROOT=/dev/vda2 PART_UEFI=/dev/vda1 PART_SWAP=/dev/vda3 /step1.sh` to start the installation.
  * This will install the entire base system into the computer, running all the required scripts.
  * Eventually it will ask for the password for `root` and for `danirod` accounts.
  * `poweroff` once done. Or just exit the SSH session and `./bootstrap.sh stop-vm`.

### Delete the virtual machine?

`./bootstrap.sh delete-vm`. It will not delete the qcow2 file.

### Install the desktop environment

The last stage needs to be run from the target system. Boot the system into the user account and

`curl -L https://raw.github.com/danirod/arch-custom-install-scripts/trunk/step_i3.sh | sh`
