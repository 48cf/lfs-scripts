#!/bin/bash

if test $(id -u) -eq 0; then
  echo "don't run this script as root"
  exit 1
fi

base_dir=$(realpath $(dirname $0))
mnt_path="${base_dir}/mnt"

if ! [ -f "${base_dir}/.image_lock" ]; then
  echo "image is not mounted, mount it using tools/mount.sh first"
  exit 1
fi

sources=(
  https://sourceware.org/pub/binutils/releases/binutils-2.41.tar.xz
  https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz
  https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.1.tar.xz
  https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz
  https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz
  https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.5.7.tar.xz
  https://ftp.gnu.org/gnu/glibc/glibc-2.38.tar.xz

  https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz
  https://invisible-mirror.net/archives/ncurses/ncurses-6.4.tar.gz
  https://ftp.gnu.org/gnu/bash/bash-5.2.15.tar.gz
  https://ftp.gnu.org/gnu/coreutils/coreutils-9.4.tar.xz
  https://ftp.gnu.org/gnu/diffutils/diffutils-3.10.tar.xz
  https://astron.com/pub/file/file-5.45.tar.gz
  https://ftp.gnu.org/gnu/findutils/findutils-4.9.0.tar.xz
  https://ftp.gnu.org/gnu/gawk/gawk-5.2.2.tar.xz
  https://ftp.gnu.org/gnu/grep/grep-3.11.tar.xz
  https://ftp.gnu.org/gnu/gzip/gzip-1.13.tar.xz
  https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz
  https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz
  https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz
  https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz
  https://tukaani.org/xz/xz-5.4.4.tar.xz

  https://ftp.gnu.org/gnu/gettext/gettext-0.22.3.tar.xz
  https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz
  https://www.cpan.org/src/5.0/perl-5.38.0.tar.xz
  https://www.python.org/ftp/python/3.11.5/Python-3.11.5.tar.xz
  https://ftp.gnu.org/gnu/texinfo/texinfo-7.0.3.tar.xz
  https://www.kernel.org/pub/linux/utils/util-linux/v2.39/util-linux-2.39.2.tar.xz
  https://ftp.gnu.org/gnu/which/which-2.21.tar.gz
  https://distfiles.ariadne.space/pkgconf/pkgconf-2.0.3.tar.xz
  https://zlib.net/fossils/zlib-1.3.tar.gz
  https://www.openssl.org/source/openssl-3.1.3.tar.gz
  https://github.com/libarchive/libarchive/releases/download/v3.7.1/libarchive-3.7.1.tar.xz
  https://github.com/void-linux/xbps/archive/refs/tags/0.59.2.tar.gz:xbps-0.59.2.tar.gz
)

for source in ${sources[@]}; do
  if [[ "${source}" == https://*:* ]]; then
    url="${source%:*}"
    output_name="${source#*://*:*}"
  else
    url="${source}"
    output_name="$(basename "${source}")"
  fi

  if ! [ -f "${mnt_path}/var/lfs/sources/${output_name}" ]; then
    wget "${url}" -O "${mnt_path}/var/lfs/sources/${output_name}"
  fi
done
