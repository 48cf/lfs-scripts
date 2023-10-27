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

mnt_path="${base_dir}/mnt"

mkdir -p "${mnt_path}"/{dev,proc,sys,run}
mount --bind /dev "${mnt_path}/dev"
mount --bind /dev/pts "${mnt_path}/dev/pts"
mount -t proc proc "${mnt_path}/proc"
mount -t sysfs sysfs "${mnt_path}/sys"
mount -t tmpfs tmpfs "${mnt_path}/run"

if [ -h "${mnt_path}/dev/shm" ]; then
  mkdir -p "${mnt_path}/$(readlink "${mnt_path}/dev/shm")"
else
  mount -t tmpfs -o nosuid,nodev tmpfs "${mnt_path}/dev/shm"
fi

unmount() {
  umount -R "${mnt_path}/dev"
  umount -R "${mnt_path}/proc"
  umount -R "${mnt_path}/sys"
  umount -R "${mnt_path}/run"
}

trap unmount EXIT

chroot "${mnt_path}" \
  /usr/bin/env -i \
  HOME=/root \
  TERM="${TERM}" \
  PS1='(lfs) \u:\w\$ ' \
  PATH=/usr/bin:/usr/sbin \
  /bin/bash --login
