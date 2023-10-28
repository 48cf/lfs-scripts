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

chown -R root:root "${mnt_path}"/{usr{,/*},bin,etc,lib,sbin,var{,/lfs/{sources,tools}}}

case $(uname -m) in
  x86_64) chown -R root:root "${mnt_path}/lib64" ;;
esac

install -m 0755 "${base_dir}/tools/make_base_files.sh" "${mnt_path}/var/lfs/"
install -m 0755 "${base_dir}/build_temp.sh" "${mnt_path}/var/lfs/"
install -m 0755 "${base_dir}/download_sources.sh" "${mnt_path}/var/lfs/"
