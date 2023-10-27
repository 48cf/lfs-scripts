#!/bin/bash

if test $(id -u) -ne 0; then
  echo "this script must be ran as root"
  exit 1
fi

base_dir=$(realpath $(dirname $0)/..)

if ! [ -f "${base_dir}/.image_lock" ]; then
  echo "image is not mounted, mount it using tools/mount.sh first"
  exit 1
fi

loop_device=$(cat "${base_dir}/.image_lock")

umount "${base_dir}/mnt/boot"
umount "${base_dir}/mnt"
losetup -D "${loop_device}"
rm "${base_dir}/.image_lock"
rmdir "${base_dir}/mnt"
