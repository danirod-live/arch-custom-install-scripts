# arch-custom-install-scripts

These are my custom install scripts for Arch Linux. These are mines.
This is not a framework. If they work for you then it is fine, but you
probably want to edit the scripts to make it work for you.

**Purpose:**

-   The install script can be used to install Arch Linux to a new
    machine.
-   If my computer ever breaks, I can use the script to quickly
    reconfigure things.
-   Usually I'll use these scripts to create virtual machines used to
    record my content.

## The install scripts

They are in the install/ directory.

Main scripts. They are meant to be run inside an Arch Linux ISO
environment:

-   system: this installs a base system. When it runs, it will ask a
    couple of questions such as the root password, the name and password
    for the admin account, and the hostname to set.
-   refind: this installs refind. It is a separate script because if I
    am dual booting, usually I'll have already installed refind by
    myself.
-   kvm: this is a shortcut to install system and refind. Only use this
    if you are using a virtual machine and the hard drive was configured
    with the scripts/diskctl script.

## The management scripts

### scripts/diskctl

Used to manage QCOW2 files. Only useful when dealing with virtual
machines. Only QEMU/KVM are supported.

-   `scripts/diskctl create [file]`: initialize an empty hard drive at
    the given location. The virtual drive is a QCOW2 file with the
    partition table already configured to three partitions:
    -   An ESP partition used for the UEFI, with a size of 1 GB.
    -   A main partition used for the main system, 27 GB.
    -   A swap partition used for the running system, with a size of 2
        GB.
-   `scripts/diskctl sparse [file] [backing-file]`: sparse an image
    file. This compacts the image to save space. The script will leave
    the rename the original file to something that ends with .orig, so
    that you can test that the sparse was done properly before deleting
    the original file. If you are trying to sparse a derived image, make
    sure to provide
-   `scripts/diskctl derive [backing-file] [target-file]`: creates a new
    image file called `target-file` which is an overlay image backed by
    the `backing-file` file. Note that `backing-file` must be relative
    to `target-file`, until I figure out how to deal with that inside
    the script, so to derive images/base.qcow2 into images/i3.qcow2, the
    parameters have to be given as
    `scripts/diskctl derive base.qcow2 images/i3.qcow2`, since
    `base.qcow2` is the relative path for `images/base.qcow2` in
    `images/i3.qcow2`.

### scripts/ovmf

Use this to grab the UEFI firmware files required by the scripts/qemu
command. This will take from your ovmf-edk2 files the OVMF_CODE.fd file,
which contains the firmware, and the OVMF_VARS.fd, which contains the
UEFI variables.

Usage: `scripts/ovmf -target=[targetdir] [-source=[sourcedir]]`

-   The target= parameter is mandatory and must indicate a directory
    where to place the files.
-   The source= parameter is optional and if not given it will use
    /usr/share/ovmf/x64 as a default.

The command will symlink the OVMF_CODE.fd file from the `sourcedir`
directory to the `targetdir` directory. This is a readonly file, so a
symlink is enough. The command will make a copy of the OVMF_VARS.fd file
from the `sourcedir` directory into the `targetdir` directory. The VM
will modify this file, so it is important to use a copy.

### scripts/qemu

Shortcut to launch qemu-system-x86_64. Can receive the following
parameters:

-   `-disk=[path to the QCOW2 file]`: this is the virtual disk used to
    store the data.
-   `-iso=[path to an Arch Linux ISO file]`: if an ISO file is given, it
    will boot in Live CD. Otherwise, it will boot the QCOW2 file.
-   `-efi=[path to the OVMF firmware location]`: points to a directory
    that should contain the OVMF_CODE.fd and OVMF_VARS.fd files, for
    instance the one chosen by the `scripts/ovmf` script.

Let's see how to boot from CD-ROM:

    scripts/ovmf -target=uefi
    scripts/qemu -disk=images/arch.qcow2 \
      -iso=$HOME/downloads/archlinux.iso \
      -efi=uefi

To boot from the hard drive, remove the -iso parameter:

    scripts/qemu -disk=images/arch.qcow2 -efi=uefi

## Virtual machine usage example

Let's see how to create a virtual machine with this:

### Preparations

1.  Download Arch Linux as an ISO file and place it in archlinux.iso.
    For instance, symlink archlinux-YYYY.MM.DD-x86_64.iso to
    archlinux.iso. If you change the location, you have to also change
    the ISO file given as parameter in step 3.
2.  `scripts/diskctl create images/base.qcow2`: this will create a new
    QCOW2 image, the one the one that we will work with. Later, we will
    create a new image backed by this one. Change the last parameter if
    you want to store your qcow2 file elsewhere.

### Install the base system

This installs a functional Arch Linux QCOW2 system. Not useful by itself
because it lacks any userland tools (like a DE), but you can use this as
a checkpoint that we will later backup so that we can derive images from
this one.

3.  `scripts/ovmf -target=images`, to copy the UEFI firmware files to
    the images dir
4.  `scripts/qemu -disk=images/base.qcow2 -iso=archlinux.iso -efi=images`:
    startup QEMU in Live CD mode. If your Arch Linux ISO file is
    elsewhere, change the -iso parameter with the proper parameter. If
    you are using a different qcow2 file, also change the -disk
    parameter. Provide some valid UEFI firmware and variables files
    because the KVM install script will install refind. (The install
    script does not support BIOS booting.)
5.  Once the system is booted, wait a minute or two. The install script
    needs to install some packages in the Live CD environment, so we
    need to wait until the pacman-init service initialises the keyring,
    or things will fail catastrophically. Check the status of the
    systemd pacman-init service. Then use
    `curl https://arch.danirod.es/install/kvm | sh`. This will start the
    main installation process.
6.  The script will ask a couple questions. When requested, provide the
    username that you want to use in your admin account, and the
    passwords for the admin account and the root account. Also provide
    the hostname of the machine (useful for networking!).
7.  A couple of minutes later, the base system will be installed.
    Shutdown the virtual machine (`poweroff` is enough).

### Checkpoints

Time to cleanup the image file to save space:

7.  Run `diskctl sparse images/base.qcow2`. If you are using a different
    image file, change it now. Sparsing the image file compacts it so
    that the unused space gets cleaned up. You can make the QCOW2 file
    smaller with this before it is ready for backup.
8.  Test the sparsed file as described below. If the sparsed file is
    successful, you can remove the .orig file that was created in the
    same directory as the sparsed QCOW2 file.
    `rm images/base.qcow2.orig`, for instance. Do not remove the sparsed
    file yet!
9.  Maybe backup this file somewhere? If you keep a backup you will not
    have to repeat steps 1 to 7 for a while. (You may be interesting in
    repeating steps 1 to 7 every month to use a fresh Arch Linux ISO
    file, however).

If you want to test the backup, maybe copy the QCOW2 file to a throwaway
file and then start QEMU without the live CD so that we boot from the
virtual drive:

``` sh
cp images/base.qcow2 images/throwaway.qcow2
scripts/qemu -disk=images/throwaway.qcow2
rm images/throwaway.qcow2
```

### Derive new images

Deriving an image means to create a new QCOW2 image that is backed by
another QCOW2 image. This creates overlay images where you use a
**backing file** as a read-only snapshot, and you store the changes made
to the disk in the QCOW2 image.

This saves space. You can have a single backing file with the Linux
installation you made in steps 1 to 7, and then you can derive multiple
hard drives: gnome.qcow2, kde.qcow2, xfce.qcow2... For each QCOW2 file,
you will only store there changes made against the original backing
file.

To derive an image, use the `diskctl derive` command from the diskctl
script. For instance:

    diskctl derive base.qcow2 images/kde.qcow2
    diskctl derive base.qcow2 images/gnome.qcow2
    diskctl derive gnome.qcow2 images/gnome-tweaks.qcow2

The first parameter given after derive is the path to the image to be
derived. The second parameter is the path of the new image file to
write. Note that the backing file path is relative to the target image.
Until I deal with this in the script, the relative path has to be
manually given when calling diskctl, which looks clunky.

### Use the new derived images

Do whatever you want with these:

    scripts/qemu -disk=images/derived-image.qcow2 -efi=images

## KVM development mode

When modifying the scripts, it is useful to start an HTTP server in the
repository root so that you can serve the live scripts to the virtual
machine over HTTP. For instance, run `python3 -m http.server 9000` in
the repository directory so that you can edit the scripts and see it
live at `http://10.0.2.2:9000/install/*`.

The `install/kvm` script can be tweaked with the ARCH_ROOT environment
variable, which indicates which hostname to use. By default it uses
https://arch.danirod.es as the server, but you can change the
environment variable to override this. For instance:

``` sh
export ARCH_ROOT=http://10.0.2.2:9000
curl $ARCH_ROOT/install/kvm | sh
```

## To-do tasks

-   diskctl
    -   Make `diskctl sparse` fail if qemu-img reports that the image
        has a backing image, to prevent the image to convert from an
        overlay structure to a flat image if not needed.
    -   Solve relative paths when deriving images inside the script, so
        that you can just provide a natural path like
        `diskctl sparse images/base.qcow2 images/gnome.qcow2` and the
        script can convert the backing_file to base.qcow2 automatically.
