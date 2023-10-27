#!/bin/bash

set -e

if test $(id -u) -eq 0; then
  echo "don't run this script as root"
  exit 1
fi

base_dir=$(realpath $(dirname $0))
build_dir="${base_dir}/build"
mnt_path="${base_dir}/mnt"

if ! [ -f "${base_dir}/.image_lock" ]; then
  echo "image is not mounted, mount it using tools/mount.sh first"
  exit 1
fi

if ! [ -d "${build_dir}" ]; then
  mkdir -p "${build_dir}"
fi

# Set up environment as per LFS chapter 4.4
# https://www.linuxfromscratch.org/lfs/view/systemd/chapter04/settingenvironment.html

set +h
umask 022

LC_ALL="C"
LFS_TARGET="$(uname -m)-lfs-linux-gnu"
PATH="/usr/bin"

if [ ! -L "/bin" ]; then
  PATH="/bin:${PATH}"
fi

PATH="${mnt_path}/var/lfs/tools/bin:${PATH}"
CONFIG_SITE="${mnt_path}/usr/share/config.site"

export LC_ALL LFS_TARGET PATH CONFIG_SITE

# Build binutils

if ! [ -f "${build_dir}/.binutils_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/binutils-2.41.tar.xz"
  mv "binutils-2.41" "binutils-src"
  touch "${build_dir}/.binutils_prepared"
fi

if ! [ -f "${build_dir}/.binutils_configured" ]; then
  mkdir -p "${build_dir}/binutils-build"
  cd "${build_dir}/binutils-build"
  "${build_dir}/binutils-src/configure" \
    --prefix="${mnt_path}/var/lfs/tools" \
    --target="${LFS_TARGET}" \
    --with-sysroot="${mnt_path}" \
    --disable-nls \
    --disable-werror \
    --enable-gprofng=no
  touch "${build_dir}/.binutils_configured"
fi

if ! [ -f "${build_dir}/.binutils_built" ]; then
  cd "${build_dir}/binutils-build"
  make -j
  touch "${build_dir}/.binutils_built"
fi

if ! [ -f "${build_dir}/.binutils_installed" ]; then
  cd "${build_dir}/binutils-build"
  make install
  touch "${build_dir}/.binutils_installed"
fi

# Build gcc

if ! [ -f "${build_dir}/.gcc_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/gcc-13.2.0.tar.xz"
  mv "gcc-13.2.0" "gcc-src"

  cd "${build_dir}/gcc-src"
  tar -xf "${mnt_path}/var/lfs/sources/mpfr-4.2.1.tar.xz"
  mv "mpfr-4.2.1" "mpfr"
  tar -xf "${mnt_path}/var/lfs/sources/gmp-6.3.0.tar.xz"
  mv "gmp-6.3.0" "gmp"
  tar -xf "${mnt_path}/var/lfs/sources/mpc-1.3.1.tar.gz"
  mv "mpc-1.3.1" "mpc"

  case $(uname -m) in
    x86_64)
      sed -e '/m64=/s/lib64/lib/' -i.orig "${build_dir}/gcc-src/gcc/config/i386/t-linux64"
      ;;
  esac

  touch "${build_dir}/.gcc_prepared"
fi

if ! [ -f "${build_dir}/.gcc_configured" ]; then
  mkdir -p "${build_dir}/gcc-build"
  cd "${build_dir}/gcc-build"
  "${build_dir}/gcc-src/configure" \
    --prefix="${mnt_path}/var/lfs/tools" \
    --target="${LFS_TARGET}" \
    --with-sysroot="${mnt_path}" \
    --with-glibc-version=2.38 \
    --with-newlib \
    --without-headers \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libssp \
    --disable-libstdcxx \
    --disable-libvtv \
    --disable-multilib \
    --disable-nls \
    --disable-shared \
    --disable-threads \
    --enable-default-pie \
    --enable-default-ssp \
    --enable-languages=c,c++
  touch "${build_dir}/.gcc_configured"
fi

if ! [ -f "${build_dir}/.gcc_built" ]; then
  cd "${build_dir}/gcc-build"
  make -j
  touch "${build_dir}/.gcc_built"
fi

if ! [ -f "${build_dir}/.gcc_installed" ]; then
  cd "${build_dir}/gcc-build"
  make install
  cat "${build_dir}/gcc-src/gcc/limitx.h" "${build_dir}/gcc-src/gcc/glimits.h" "${build_dir}/gcc-src/gcc/limity.h" > \
    "$(dirname $("${LFS_TARGET}-gcc" -print-libgcc-file-name))/include/limits.h"
  touch "${build_dir}/.gcc_installed"
fi

# Build linux headers

if ! [ -f "${build_dir}/.linux_headers_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/linux-6.5.7.tar.xz"
  mv "linux-6.5.7" "linux-src"
  touch "${build_dir}/.linux_headers_prepared"
fi

if ! [ -f "${build_dir}/.linux_headers_installed" ]; then
  cd "${build_dir}/linux-src"
  make mrproper
  make headers
  find "usr/include" -type f ! -name '*.h' -delete
  cp -r "usr/include" "${mnt_path}/usr"
  touch "${build_dir}/.linux_headers_installed"
fi

# Build glibc

if ! [ -f "${build_dir}/.glibc_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/glibc-2.38.tar.xz"
  mv "glibc-2.38" "glibc-src"
  patch -Np1 -d "glibc-src" -i "${base_dir}/patches/glibc-2.38-fhs-1.patch"
  case $(uname -m) in
    x86_64)
      ln -sf "../lib/ld-linux-x86-64.so.2" "${mnt_path}/lib64"
      ln -sf "../lib/ld-linux-x86-64.so.2" "${mnt_path}/lib64/ld-lsb-x86-64.so.3"
      ;;
  esac
  touch "${build_dir}/.glibc_prepared"
fi

if ! [ -f "${build_dir}/.glibc_configured" ]; then
  mkdir -p "${build_dir}/glibc-build"
  echo "rootsbindir=/usr/sbin" >"${build_dir}/glibc-build/configparms"
  cd "${build_dir}/glibc-build"
  "${build_dir}/glibc-src/configure" \
    --prefix=/usr \
    --build=$("${build_dir}/glibc-src/scripts/config.guess") \
    --host="${LFS_TARGET}" \
    --with-headers="${mnt_path}/usr/include" \
    --disable-nscd \
    --enable-kernel=4.14 \
    libc_cv_slibdir=/usr/lib
  touch "${build_dir}/.glibc_configured"
fi

if ! [ -f "${build_dir}/.glibc_built" ]; then
  cd "${build_dir}/glibc-build"
  make -j
  touch "${build_dir}/.glibc_built"
fi

if ! [ -f "${build_dir}/.glibc_installed" ]; then
  cd "${build_dir}/glibc-build"
  make DESTDIR="${mnt_path}" install
  sed '/RTLDLIST=/s@/usr@@g' -i "${mnt_path}/usr/bin/ldd"
  touch "${build_dir}/.glibc_installed"
fi

# Build libstdc++

if ! [ -f "${build_dir}/.libstdcpp_configured" ]; then
  mkdir -p "${build_dir}/libstdcpp-build"
  cd "${build_dir}/libstdcpp-build"
  "${build_dir}/gcc-src/libstdc++-v3/configure" \
    --prefix=/usr \
    --host="${LFS_TARGET}" \
    --build=$("${build_dir}/gcc-src/config.guess") \
    --with-gxx-include-dir="/var/lfs/tools/${LFS_TARGET}/include/c++/13.2.0" \
    --disable-libstdcxx-pch \
    --disable-multilib \
    --disable-nls
  touch "${build_dir}/.libstdcpp_configured"
fi

if ! [ -f "${build_dir}/.libstdcpp_built" ]; then
  cd "${build_dir}/libstdcpp-build"
  make -j
  touch "${build_dir}/.libstdcpp_built"
fi

if ! [ -f "${build_dir}/.libstdcpp_installed" ]; then
  cd "${build_dir}/libstdcpp-build"
  make DESTDIR="${mnt_path}" install
  rm "${mnt_path}/usr/lib"/lib{stdc++{,exp,fs},supc++}.la
  touch "${build_dir}/.libstdcpp_installed"
fi

# Build m4

if ! [ -f "${build_dir}/.m4_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/m4-1.4.19.tar.xz"
  mv "m4-1.4.19" "m4-src"
  touch "${build_dir}/.m4_prepared"
fi

if ! [ -f "${build_dir}/.m4_configured" ]; then
  mkdir -p "${build_dir}/m4-build"
  cd "${build_dir}/m4-build"
  "${build_dir}/m4-src/configure" \
    --prefix=/usr \
    --host="${LFS_TARGET}" \
    --build=$("${build_dir}/m4-src/build-aux/config.guess")
  touch "${build_dir}/.m4_configured"
fi

if ! [ -f "${build_dir}/.m4_built" ]; then
  cd "${build_dir}/m4-build"
  make -j
  touch "${build_dir}/.m4_built"
fi

if ! [ -f "${build_dir}/.m4_installed" ]; then
  cd "${build_dir}/m4-build"
  make DESTDIR="${mnt_path}" install
  touch "${build_dir}/.m4_installed"
fi

# Build ncurses

if ! [ -f "${build_dir}/.ncurses_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/ncurses-6.4.tar.gz"
  mv "ncurses-6.4" "ncurses-src"
  sed -i s/mawk// "${build_dir}/ncurses-src/configure"
  touch "${build_dir}/.ncurses_prepared"
fi

if ! [ -f "${build_dir}/.ncurses_host_configured" ]; then
  mkdir -p "${build_dir}/ncurses-host-build"
  cd "${build_dir}/ncurses-host-build"
  "${build_dir}/ncurses-src/configure"
  touch "${build_dir}/.ncurses_host_configured"
fi

if ! [ -f "${build_dir}/.ncurses_host_built" ]; then
  cd "${build_dir}/ncurses-host-build"
  make -C include
  make -j -C progs tic
  touch "${build_dir}/.ncurses_host_built"
fi

if ! [ -f "${build_dir}/.ncurses_configured" ]; then
  mkdir -p "${build_dir}/ncurses-build"
  cd "${build_dir}/ncurses-build"
  "${build_dir}/ncurses-src/configure" \
    --host="${LFS_TARGET}" \
    --build=$("${build_dir}/ncurses-src/config.guess") \
    --mandir=/usr/share/man \
    --disable-stripping \
    --enable-widec \
    --with-cxx-shared \
    --with-manpage-format=normal \
    --with-shared \
    --without-ada \
    --without-debug \
    --without-normal
  touch "${build_dir}/.ncurses_configured"
fi

if ! [ -f "${build_dir}/.ncurses_built" ]; then
  cd "${build_dir}/ncurses-build"
  make -j
  touch "${build_dir}/.ncurses_built"
fi

if ! [ -f "${build_dir}/.ncurses_installed" ]; then
  cd "${build_dir}/ncurses-build"
  make DESTDIR="${mnt_path}" TIC_PATH="${build_dir}/ncurses-host-build/progs/tic" install
  echo "INPUT(-lncursesw)" >"${mnt_path}/usr/lib/libncurses.so"
  touch "${build_dir}/.ncurses_installed"
fi

# Build bash

if ! [ -f "${build_dir}/.bash_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/bash-5.2.15.tar.gz"
  mv "bash-5.2.15" "bash-src"
  touch "${build_dir}/.bash_prepared"
fi

if ! [ -f "${build_dir}/.bash_configured" ]; then
  mkdir -p "${build_dir}/bash-build"
  cd "${build_dir}/bash-build"
  "${build_dir}/bash-src/configure" \
    --prefix=/usr \
    --host="${LFS_TARGET}" \
    --build=$(sh "${build_dir}/bash-src/support/config.guess") \
    --without-bash-malloc
  touch "${build_dir}/.bash_configured"
fi

if ! [ -f "${build_dir}/.bash_built" ]; then
  cd "${build_dir}/bash-build"
  make -j
  touch "${build_dir}/.bash_built"
fi

if ! [ -f "${build_dir}/.bash_installed" ]; then
  cd "${build_dir}/bash-build"
  make DESTDIR="${mnt_path}" install
  ln -s "bash" "${mnt_path}/bin/sh"
  touch "${build_dir}/.bash_installed"
fi

# Build coreutils

if ! [ -f "${build_dir}/.coreutils_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/coreutils-9.4.tar.xz"
  mv "coreutils-9.4" "coreutils-src"
  touch "${build_dir}/.coreutils_prepared"
fi

if ! [ -f "${build_dir}/.coreutils_configured" ]; then
  mkdir -p "${build_dir}/coreutils-build"
  cd "${build_dir}/coreutils-build"
  "${build_dir}/coreutils-src/configure" \
    --prefix=/usr \
    --host="${LFS_TARGET}" \
    --build=$("${build_dir}/coreutils-src/build-aux/config.guess") \
    --enable-install-program=hostname \
    --enable-no-install-program=kill,uptime
  touch "${build_dir}/.coreutils_configured"
fi

if ! [ -f "${build_dir}/.coreutils_built" ]; then
  cd "${build_dir}/coreutils-build"
  make -j
  touch "${build_dir}/.coreutils_built"
fi

if ! [ -f "${build_dir}/.coreutils_installed" ]; then
  cd "${build_dir}/coreutils-build"
  make DESTDIR="${mnt_path}" install
  mv "${mnt_path}/usr/bin/chroot" "${mnt_path}/usr/sbin"
  mkdir -p "${mnt_path}/usr/share/man/man8"
  mv "${mnt_path}/usr/share/man/man1/chroot.1" "${mnt_path}/usr/share/man/man8/chroot.8"
  sed -i 's/"1"/"8"/' "${mnt_path}/usr/share/man/man8/chroot.8"
  touch "${build_dir}/.coreutils_installed"
fi

# Build diffutils

if ! [ -f "${build_dir}/.diffutils_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/diffutils-3.10.tar.xz"
  mv "diffutils-3.10" "diffutils-src"
  touch "${build_dir}/.diffutils_prepared"
fi

if ! [ -f "${build_dir}/.diffutils_configured" ]; then
  mkdir -p "${build_dir}/diffutils-build"
  cd "${build_dir}/diffutils-build"
  "${build_dir}/diffutils-src/configure" \
    --prefix=/usr \
    --host="${LFS_TARGET}" \
    --build=$("${build_dir}/diffutils-src/build-aux/config.guess")
  touch "${build_dir}/.diffutils_configured"
fi

if ! [ -f "${build_dir}/.diffutils_built" ]; then
  cd "${build_dir}/diffutils-build"
  make -j
  touch "${build_dir}/.diffutils_built"
fi

if ! [ -f "${build_dir}/.diffutils_installed" ]; then
  cd "${build_dir}/diffutils-build"
  make DESTDIR="${mnt_path}" install
  touch "${build_dir}/.diffutils_installed"
fi

# Build file

if ! [ -f "${build_dir}/.file_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/file-5.45.tar.gz"
  mv "file-5.45" "file-src"
  touch "${build_dir}/.file_prepared"
fi

if ! [ -f "${build_dir}/.file_host_configured" ]; then
  mkdir -p "${build_dir}/file-host-build"
  cd "${build_dir}/file-host-build"
  "${build_dir}/file-src/configure" \
    --disable-bzlib \
    --disable-libseccomp \
    --disable-xzlib \
    --disable-zlib
  touch "${build_dir}/.file_host_configured"
fi

if ! [ -f "${build_dir}/.file_host_built" ]; then
  cd "${build_dir}/file-host-build"
  make -j
  touch "${build_dir}/.file_host_built"
fi

if ! [ -f "${build_dir}/.file_configured" ]; then
  mkdir -p "${build_dir}/file-build"
  cd "${build_dir}/file-build"
  "${build_dir}/file-src/configure" \
    --prefix=/usr \
    --host="${LFS_TARGET}" \
    --build=$("${build_dir}/file-src/config.guess")
  touch "${build_dir}/.file_configured"
fi

if ! [ -f "${build_dir}/.file_built" ]; then
  cd "${build_dir}/file-build"
  make FILE_COMPILE="${build_dir}/file-host-build/src/file" -j
  touch "${build_dir}/.file_built"
fi

if ! [ -f "${build_dir}/.file_installed" ]; then
  cd "${build_dir}/file-build"
  make DESTDIR="${mnt_path}" install
  rm "${mnt_path}/usr/lib/libmagic.la"
  touch "${build_dir}/.file_installed"
fi

# Build findutils

if ! [ -f "${build_dir}/.findutils_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/findutils-4.9.0.tar.xz"
  mv "findutils-4.9.0" "findutils-src"
  touch "${build_dir}/.findutils_prepared"
fi

if ! [ -f "${build_dir}/.findutils_configured" ]; then
  mkdir -p "${build_dir}/findutils-build"
  cd "${build_dir}/findutils-build"
  "${build_dir}/findutils-src/configure" \
    --prefix=/usr \
    --host="${LFS_TARGET}" \
    --build=$("${build_dir}/findutils-src/build-aux/config.guess") \
    --localstatedir=/var/lib/locate
  touch "${build_dir}/.findutils_configured"
fi

if ! [ -f "${build_dir}/.findutils_built" ]; then
  cd "${build_dir}/findutils-build"
  make -j
  touch "${build_dir}/.findutils_built"
fi

if ! [ -f "${build_dir}/.findutils_installed" ]; then
  cd "${build_dir}/findutils-build"
  make DESTDIR="${mnt_path}" install
  touch "${build_dir}/.findutils_installed"
fi

# Build gawk

if ! [ -f "${build_dir}/.gawk_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/gawk-5.2.2.tar.xz"
  mv "gawk-5.2.2" "gawk-src"
  sed -i 's/extras//' "${build_dir}/gawk-src/Makefile.in"
  touch "${build_dir}/.gawk_prepared"
fi

if ! [ -f "${build_dir}/.gawk_configured" ]; then
  mkdir -p "${build_dir}/gawk-build"
  cd "${build_dir}/gawk-build"
  "${build_dir}/gawk-src/configure" \
    --prefix=/usr \
    --host="${LFS_TARGET}" \
    --build=$("${build_dir}/gawk-src/build-aux/config.guess")
  touch "${build_dir}/.gawk_configured"
fi

if ! [ -f "${build_dir}/.gawk_built" ]; then
  cd "${build_dir}/gawk-build"
  make -j
  touch "${build_dir}/.gawk_built"
fi

if ! [ -f "${build_dir}/.gawk_installed" ]; then
  cd "${build_dir}/gawk-build"
  make DESTDIR="${mnt_path}" install
  touch "${build_dir}/.gawk_installed"
fi

# Build grep

if ! [ -f "${build_dir}/.grep_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/grep-3.11.tar.xz"
  mv "grep-3.11" "grep-src"
  touch "${build_dir}/.grep_prepared"
fi

if ! [ -f "${build_dir}/.grep_configured" ]; then
  mkdir -p "${build_dir}/grep-build"
  cd "${build_dir}/grep-build"
  "${build_dir}/grep-src/configure" \
    --prefix=/usr \
    --host="${LFS_TARGET}" \
    --build=$("${build_dir}/grep-src/build-aux/config.guess")
  touch "${build_dir}/.grep_configured"
fi

if ! [ -f "${build_dir}/.grep_built" ]; then
  cd "${build_dir}/grep-build"
  make -j
  touch "${build_dir}/.grep_built"
fi

if ! [ -f "${build_dir}/.grep_installed" ]; then
  cd "${build_dir}/grep-build"
  make DESTDIR="${mnt_path}" install
  touch "${build_dir}/.grep_installed"
fi

# Build gzip

if ! [ -f "${build_dir}/.gzip_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/gzip-1.13.tar.xz"
  mv "gzip-1.13" "gzip-src"
  touch "${build_dir}/.gzip_prepared"
fi

if ! [ -f "${build_dir}/.gzip_configured" ]; then
  mkdir -p "${build_dir}/gzip-build"
  cd "${build_dir}/gzip-build"
  "${build_dir}/gzip-src/configure" \
    --prefix=/usr \
    --host="${LFS_TARGET}"
  touch "${build_dir}/.gzip_configured"
fi

if ! [ -f "${build_dir}/.gzip_built" ]; then
  cd "${build_dir}/gzip-build"
  make -j
  touch "${build_dir}/.gzip_built"
fi

if ! [ -f "${build_dir}/.gzip_installed" ]; then
  cd "${build_dir}/gzip-build"
  make DESTDIR="${mnt_path}" install
  touch "${build_dir}/.gzip_installed"
fi

# Build make

if ! [ -f "${build_dir}/.make_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/make-4.4.1.tar.gz"
  mv "make-4.4.1" "make-src"
  touch "${build_dir}/.make_prepared"
fi

if ! [ -f "${build_dir}/.make_configured" ]; then
  mkdir -p "${build_dir}/make-build"
  cd "${build_dir}/make-build"
  "${build_dir}/make-src/configure" \
    --prefix=/usr \
    --host="${LFS_TARGET}" \
    --build=$("${build_dir}/make-src/build-aux/config.guess") \
    --without-guile
  touch "${build_dir}/.make_configured"
fi

if ! [ -f "${build_dir}/.make_built" ]; then
  cd "${build_dir}/make-build"
  make -j
  touch "${build_dir}/.make_built"
fi

if ! [ -f "${build_dir}/.make_installed" ]; then
  cd "${build_dir}/make-build"
  make DESTDIR="${mnt_path}" install
  touch "${build_dir}/.make_installed"
fi

# Build patch

if ! [ -f "${build_dir}/.patch_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/patch-2.7.6.tar.xz"
  mv "patch-2.7.6" "patch-src"
  touch "${build_dir}/.patch_prepared"
fi

if ! [ -f "${build_dir}/.patch_configured" ]; then
  mkdir -p "${build_dir}/patch-build"
  cd "${build_dir}/patch-build"
  "${build_dir}/patch-src/configure" \
    --prefix=/usr \
    --host="${LFS_TARGET}" \
    --build=$("${build_dir}/patch-src/build-aux/config.guess")
  touch "${build_dir}/.patch_configured"
fi

if ! [ -f "${build_dir}/.patch_built" ]; then
  cd "${build_dir}/patch-build"
  make -j
  touch "${build_dir}/.patch_built"
fi

if ! [ -f "${build_dir}/.patch_installed" ]; then
  cd "${build_dir}/patch-build"
  make DESTDIR="${mnt_path}" install
  touch "${build_dir}/.patch_installed"
fi

# Build sed

if ! [ -f "${build_dir}/.sed_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/sed-4.9.tar.xz"
  mv "sed-4.9" "sed-src"
  touch "${build_dir}/.sed_prepared"
fi

if ! [ -f "${build_dir}/.sed_configured" ]; then
  mkdir -p "${build_dir}/sed-build"
  cd "${build_dir}/sed-build"
  "${build_dir}/sed-src/configure" \
    --prefix=/usr \
    --host="${LFS_TARGET}" \
    --build=$("${build_dir}/sed-src/build-aux/config.guess")
  touch "${build_dir}/.sed_configured"
fi

if ! [ -f "${build_dir}/.sed_built" ]; then
  cd "${build_dir}/sed-build"
  make -j
  touch "${build_dir}/.sed_built"
fi

if ! [ -f "${build_dir}/.sed_installed" ]; then
  cd "${build_dir}/sed-build"
  make DESTDIR="${mnt_path}" install
  touch "${build_dir}/.sed_installed"
fi

# Build tar

if ! [ -f "${build_dir}/.tar_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/tar-1.35.tar.xz"
  mv "tar-1.35" "tar-src"
  touch "${build_dir}/.tar_prepared"
fi

if ! [ -f "${build_dir}/.tar_configured" ]; then
  mkdir -p "${build_dir}/tar-build"
  cd "${build_dir}/tar-build"
  "${build_dir}/tar-src/configure" \
    --prefix=/usr \
    --host="${LFS_TARGET}" \
    --build=$("${build_dir}/tar-src/build-aux/config.guess")
  touch "${build_dir}/.tar_configured"
fi

if ! [ -f "${build_dir}/.tar_built" ]; then
  cd "${build_dir}/tar-build"
  make -j
  touch "${build_dir}/.tar_built"
fi

if ! [ -f "${build_dir}/.tar_installed" ]; then
  cd "${build_dir}/tar-build"
  make DESTDIR="${mnt_path}" install
  touch "${build_dir}/.tar_installed"
fi

# Build xz

if ! [ -f "${build_dir}/.xz_prepared" ]; then
  cd "${build_dir}"
  tar -xf "${mnt_path}/var/lfs/sources/xz-5.4.4.tar.xz"
  mv "xz-5.4.4" "xz-src"
  touch "${build_dir}/.xz_prepared"
fi

if ! [ -f "${build_dir}/.xz_configured" ]; then
  mkdir -p "${build_dir}/xz-build"
  cd "${build_dir}/xz-build"
  "${build_dir}/xz-src/configure" \
    --prefix=/usr \
    --host="${LFS_TARGET}" \
    --build=$("${build_dir}/xz-src/build-aux/config.guess") \
    --docdir=/usr/share/doc/xz-5.4.4 \
    --disable-static
  touch "${build_dir}/.xz_configured"
fi

if ! [ -f "${build_dir}/.xz_built" ]; then
  cd "${build_dir}/xz-build"
  make -j
  touch "${build_dir}/.xz_built"
fi

if ! [ -f "${build_dir}/.xz_installed" ]; then
  cd "${build_dir}/xz-build"
  make DESTDIR="${mnt_path}" install
  rm "${mnt_path}/usr/lib/liblzma.la"
  touch "${build_dir}/.xz_installed"
fi

# Build binutils (pass 2)

if ! [ -f "${build_dir}/.binutils_p2_prepared" ]; then
  sed '6009s/$add_dir//' -i "${build_dir}/binutils-src/ltmain.sh"
  touch "${build_dir}/.binutils_p2_prepared"
fi

if ! [ -f "${build_dir}/.binutils_p2_configured" ]; then
  mkdir -p "${build_dir}/binutils-p2-build"
  cd "${build_dir}/binutils-p2-build"
  "${build_dir}/binutils-src/configure" \
    --prefix=/usr \
    --host="${LFS_TARGET}" \
    --build=$("${build_dir}/binutils-src/config.guess") \
    --disable-nls \
    --disable-werror \
    --enable-64-bit-bfd \
    --enable-gprofng=no \
    --enable-shared
  touch "${build_dir}/.binutils_p2_configured"
fi

if ! [ -f "${build_dir}/.binutils_p2_built" ]; then
  cd "${build_dir}/binutils-p2-build"
  make -j
  touch "${build_dir}/.binutils_p2_built"
fi

if ! [ -f "${build_dir}/.binutils_p2_installed" ]; then
  cd "${build_dir}/binutils-p2-build"
  make DESTDIR="${mnt_path}" install
  rm "${mnt_path}/usr/lib"/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
  touch "${build_dir}/.binutils_p2_installed"
fi

# Build gcc (pass 2)

if ! [ -f "${build_dir}/.gcc_p2_prepared" ]; then
  sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i "${build_dir}/gcc-src/libgcc/Makefile.in" "${build_dir}/gcc-src/libstdc++-v3/include/Makefile.in"
  touch "${build_dir}/.gcc_p2_prepared"
fi

if ! [ -f "${build_dir}/.gcc_p2_configured" ]; then
  mkdir -p "${build_dir}/gcc-p2-build"
  cd "${build_dir}/gcc-p2-build"
  "${build_dir}/gcc-src/configure" \
    LDFLAGS_FOR_TARGET="-L${build_dir}/gcc-p2-build/${LFS_TARGET}/libgcc" \
    --prefix=/usr \
    --host="${LFS_TARGET}" \
    --target="${LFS_TARGET}" \
    --build=$("${build_dir}/gcc-src/config.guess") \
    --with-build-sysroot="${mnt_path}" \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libsanitizer \
    --disable-libssp \
    --disable-libvtv \
    --disable-multilib \
    --disable-nls \
    --enable-default-pie \
    --enable-default-ssp \
    --enable-languages=c,c++
  touch "${build_dir}/.gcc_p2_configured"
fi

if ! [ -f "${build_dir}/.gcc_p2_built" ]; then
  cd "${build_dir}/gcc-p2-build"
  make -j
  touch "${build_dir}/.gcc_p2_built"
fi

if ! [ -f "${build_dir}/.gcc_p2_installed" ]; then
  cd "${build_dir}/gcc-p2-build"
  make DESTDIR="${mnt_path}" install
  ln -s "gcc" "${mnt_path}/usr/bin/cc"
  touch "${build_dir}/.gcc_p2_installed"
fi
