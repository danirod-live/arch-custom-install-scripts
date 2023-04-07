#!/bin/sh

# Make sure that TARGET_NBD is set.
if [ -z "$TARGET_NBD" ]; then
	echo "Please set the TARGET_NDB variable"
	exit 1
fi

# Owner user should own the image.
if [ -z "$OWNER_USER" ]; then
	echo "Please set the OWNER_USER variable"
	exit 1
fi

set -ex

# Create the image file.
qemu-img create -f qcow2 archlinux.qcow2 20G

# Mount it and format it
qemu-nbd -c $TARGET_NBD archlinux.qcow2
sudo sfdisk $TARGET_NBD <<EOF
label: gpt
unit: sectors
first-lba: 2048
last-lba: 41943006
sector-size: 512

/dev/nbd0p1 : start=        2048, size=     1048576, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
/dev/nbd0p2 : start=     1050624, size=    38795264, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
/dev/nbd0p3 : start=    39845888, size=     2095104, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
EOF
qemu-nbd --disconnect $TARGET_NBD

# Belong to the given user so that can use it.
chown $OWNER_USER archlinux.qcow2
