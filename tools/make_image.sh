#!/bin/bash

if test $(id -u) -ne 0; then
  echo "this script must be ran as root"
  exit 1
fi

base_dir=$(realpath $(dirname $0)/..)

if [ -f "${base_dir}/image" ]; then
  echo "image already exist, remove if you wish to proceed"
  exit 1
fi

if ! type -t sgdisk >/dev/null; then
  echo "sgdisk not found, make sure to install sgdisk"
  exit 1
fi

if ! type -t mkfs.vfat >/dev/null; then
  echo "mkfs.vfat not found, make sure to install dosfstools"
  exit 1
fi

if ! type -t mkfs.ext4 >/dev/null; then
  echo "mkfs.ext4 not found, make sure to install e2fsprogs"
  exit 1
fi

image_size=$((1024*1024*1024*16))
loop_device=$(losetup -f)

sudo -u \#${SUDO_UID} fallocate -l "${image_size}" "${base_dir}/image"
sgdisk -n 1:2048:411648 -n 2:411649 -t 1:ef00 -t 2:8300 "${base_dir}/image"

losetup "${loop_device}" "${base_dir}/image"
trap "losetup -D ${loop_device}" EXIT

partprobe "${loop_device}"
mkfs.vfat -F32 "${loop_device}p1"
mkfs.ext4 "${loop_device}p2"
