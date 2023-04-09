#!/bin/sh

# Assert that nbd is loaded.
if ! (lsmod | grep -q nbd) ; then
	echo "Missing nbd module, maybe \`modprobe nbd\`?"
	exit 1
fi

if [ -z "$TARGET_NBD" ]; then
	echo "Assuming TARGET_NBD is /dev/nbd0. If device busy, change it with TARGET_NBD=new"
	TARGET_NBD=/dev/nbd0
fi

if [ -z "$TARGET_FILE" ]; then
	TARGET_FILE=archlinux.qcow2
fi

cd "$(dirname $0)"
set -e

help() {
	echo "$0 [action]"
	echo "Actions:"
	echo
	echo "  create  :: creates a base QCOW2 pre-partitioned image"
	echo "  sparse  :: sparses the QCOW2 image to reclaim host space"
	echo "  help    :: print help message"
}

create() {
	# Create the image file.
	qemu-img create -f qcow2 "$TARGET_FILE" 20G -q
	# Mount it and format it
	echo "Interacting with the nbd system... you might be asked for your password here"
	sudo qemu-nbd -c "$TARGET_NBD" -f qcow2 "$TARGET_FILE"
	sudo sfdisk -q "$TARGET_NBD" <<EOF
	label: gpt
	unit: sectors
	first-lba: 2048
	last-lba: 41943006
	sector-size: 512

	/dev/nbd0p1 : start=        2048, size=     1048576, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
	/dev/nbd0p2 : start=     1050624, size=    38795264, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
	/dev/nbd0p3 : start=    39845888, size=     2095104, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
EOF
	sudo qemu-nbd --disconnect "$TARGET_NBD"
	echo "Successfully initialised $TARGET_FILE!"
}

sparse() {
	virt-sparsify --in-place "$TARGET_FILE"
}

# Must have information about what to do
if [[ "$#" -lt 1 ]]; then
	help
	exit 1
fi

action=$1
shift 1
case "$action" in
	help) help ;;
	create) create ;;
	sparse) sparse ;;
	*) echo "Unknown option $option" ;;
esac
