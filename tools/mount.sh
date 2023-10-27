#!/bin/bash

if test $(id -u) -ne 0; then
  echo "this script must be ran as root"
  exit 1
fi

base_dir=$(realpath $(dirname $0)/..)

if ! [ -f "${base_dir}/image" ]; then
  echo "image doesn't exist, create it using tools/make_image.sh first"
  exit 1
fi

loop_device=$(losetup -f)

losetup "${loop_device}" "${base_dir}/image"
echo "${loop_device}" > "${base_dir}/.image_lock"
partprobe "${loop_device}"

if ! [ -d "${base_dir}/mnt" ]; then
  sudo -u \#${SUDO_UID} mkdir "${base_dir}/mnt"
fi

mount "${loop_device}p2" "${base_dir}/mnt"
mkdir -p "${base_dir}/mnt/boot"
mount "${loop_device}p1" "${base_dir}/mnt/boot"
