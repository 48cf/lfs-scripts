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

mkdir -p "${mnt_path}"/{etc,var{,/lfs/{sources,tools}}} "${mnt_path}"/usr/{bin,lib,sbin}

for dir in bin lib sbin; do
  ln -sf "usr/${dir}" "${mnt_path}/${dir}"
done

chown ${SUDO_UID}:${SUDO_GID} "${mnt_path}"/{usr{,/*},bin,etc,lib,sbin,var{,/lfs/{sources,tools}}}

case $(uname -m) in
  x86_64)
    mkdir -p "${mnt_path}/lib64"
    chown ${SUDO_UID}:${SUDO_GID} "${mnt_path}/lib64"
    ;;
esac
