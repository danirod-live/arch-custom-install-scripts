#!/bin/bash

cd "$(dirname $0)"
set -e

# We use the system socket.
export LIBVIRT_DEFAULT_URI=qemu:///system

# The domain
export DOMAIN_NAME="ArchLinux"

help() {
	echo "$0 [action] [...parameters]"
	echo "Actions:"
	echo
	echo "  create-vm              :: create the virtual machine"
	echo "  start-vm               :: restart the virtual machine"
	echo "  stop-vm                :: stop the virtual machine"
	echo "  attach-vm              :: graphically open the virtual machine"
	echo "  delete-vm              :: destroy the virtual machine"
	echo
	echo "  is-running             :: test if the VM is running"
	echo "  get-ip                 :: get the IP address of the VM"
	echo "  ssh                    :: connect via SSH to the virtual machine"
	echo "  create-snapshot [name] :: create a snapshot for the name [name]"
	echo "  list-snapshot          :: list all the snapshots for the machine"
	echo "  restore-snapshot       :: go back to a previous snapshot"
}

dump_xml() {
	virt-install \
		--dry-run \
		--print-xml \
		--name $DOMAIN_NAME \
		--memory 2048 \
		--vcpus vcpus=2,maxvcpus=4 \
		--cpu=host \
		--cdrom archlinux.iso \
		--disk archlinux.qcow2,size=30 \
		--osinfo archlinux \
		--graphics=vnc \
		--boot uefi \
		--noautoconsole
}

create_vm() {
	virt-install \
		--name $DOMAIN_NAME \
		--memory 2048 \
		--vcpus vcpus=2,maxvcpus=4 \
		--cpu=host \
		--cdrom archlinux.iso \
		--disk archlinux.qcow2 \
		--osinfo archlinux \
		--graphics=vnc \
		--boot uefi \
		--noautoconsole
}

is_running() {
	case "$1" in
		--quiet|-q)
			QUIET=1
			;;
		*)
			QUIET=0
			;;
	esac
	if virsh list --name | grep -q $DOMAIN_NAME ; then
		[[ $QUIET == 0 ]] && echo "Running"
		return 0
	else
		[[ $QUIET == 0 ]] && echo "Not running"
		return 1
	fi
}

start_vm() {
	virsh start $DOMAIN_NAME
}

create_snapshot() {
	if [[ "$#" -lt 1 ]]; then
		help
		exit 1
	fi

	virsh managedsave $DOMAIN_NAME
	virsh snapshot-create-as $DOMAIN_NAME "$*"
	virsh start $DOMAIN_NAME
}

stop_vm() {
	if is_running --quiet ; then
		virsh destroy $DOMAIN_NAME
	fi
}

delete_vm() {
	stop_vm
	virsh undefine $DOMAIN_NAME --nvram
}

list_snapshot() {
	virsh snapshot-list $DOMAIN_NAME --name
}

restore_snapshot() {
	NAME=$1
	virsh snapshot-revert $DOMAIN_NAME --snapshotname $1
}

delete_snapshot() {
	NAME=$1
	virsh snapshot-delete $DOMAIN_NAME --snapshotname $1
}

attach_vm() {
	virt-viewer $DOMAIN_NAME
}

get_ip() {
	if ! is_running --quiet ; then
		echo "Not running"
		exit 1
	fi
	virsh domifaddr $DOMAIN_NAME | tail -n2 | head -n1 | awk '{ print $4 }' | cut -d'/' -f1
}

connect_ssh() {
	if ! get_ip ; then
		exit 1
	fi
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${TARGET_USER:-root}@$(get_ip)
}

remote_sh() {
	if ! get_ip ; then
		exit 1
	fi
	REMOTE_DIR=$(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${TARGET_USER:-root}@$(get_ip) 'mktemp -d')
	scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no step1.sh step2.sh step3.sh root@$(get_ip):/
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${TARGET_USER:-root}@$(get_ip) 'bash -s'
}

copy_base_files() {
	scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no step1.sh step2.sh step3.sh root@$(get_ip):/
}

# Must have information about what to do
if [[ "$#" -lt 1 ]]; then
	help
	exit 1
fi

action=$1
shift 1
case "$action" in
	help) help "$0" ;;
	create-vm) create_vm "$*" ;;
	dump-xml) dump_xml "$*" ;;
	start-vm) start_vm "$*" ;;
	attach-vm) attach_vm "$*" ;;
	stop-vm) stop_vm "$*" ;;
	is-running) is_running "$*" ;;
	create-snapshot) create_snapshot "$*" ;;
	list-snapshot) list_snapshot "$*" ;;
	restore-snapshot) restore_snapshot "$*" ;;
	delete-snapshot) delete_snapshot "$*" ;;
	delete-vm) delete_vm "$*" ;;
	get-ip) get_ip "$*" ;;
	ssh) connect_ssh "$*" ;;
	remote-sh) remote_sh "$*" ;;
	copy-base) copy_base_files "$*" ;;
	*) echo "Unknown option $option" ;;
esac
