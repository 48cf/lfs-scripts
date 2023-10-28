#!/bin/bash

set -e

if test $(id -u) -ne 0; then
  echo "this script must be ran as root"
  exit 1
fi

base_dir=$(pwd)
build_dir="${base_dir}/distro-build"
repo_dir="${base_dir}/distro-repo"

if ! [ -d "${build_dir}" ]; then
  mkdir -p "${build_dir}"
fi

if ! [ -d "${repo_dir}" ]; then
  mkdir -p "${repo_dir}"
fi

# Build man-pages

if ! [ -f "${build_dir}/.man_pages_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/man-pages-6.05.01.tar.xz"
  mv "man-pages-6.05.01" "man-pages-src"
  touch "${build_dir}/.man_pages_prepared"
fi

if ! [ -f "${build_dir}/.man_pages_installed" ]; then
  mkdir -p "${build_dir}/man-pages-collect"
  cd "${build_dir}/man-pages-src"
  make prefix="${build_dir}/man-pages-collect/usr" install
  touch "${build_dir}/.man_pages_installed"
fi

if ! [ -f "${build_dir}/.man_pages_packaged" ]; then
  cd "${repo_dir}"
  xbps-create \
    -A noarch \
    -n man-pages-6.05.01_1 \
    -s "Linux man pages" \
    "${build_dir}/man-pages-collect"
  xbps-rindex -a "${repo_dir}/man-pages-6.05.01_1.noarch.xbps"
  touch "${build_dir}/.man_pages_packaged"
fi

# Build iana-etc

if ! [ -f "${build_dir}/.iana_etc_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/iana-etc-20230929.tar.gz"
  mv "iana-etc-20230929" "iana-etc-src"
  touch "${build_dir}/.iana_etc_prepared"
fi

if ! [ -f "${build_dir}/.iana_etc_installed" ]; then
  mkdir -p "${build_dir}/iana-etc-collect"
  mkdir -p "${build_dir}/iana-etc-collect/etc"
  cp "${build_dir}/iana-etc-src"/{services,protocols} "${build_dir}/iana-etc-collect/etc"
  touch "${build_dir}/.iana_etc_installed"
fi

if ! [ -f "${build_dir}/.iana_etc_packaged" ]; then
  cd "${repo_dir}"
  xbps-create \
    -A noarch \
    -n iana-etc-20230929_1 \
    -s "/etc/protocols and /etc/services provided by IANA" \
    "${build_dir}/iana-etc-collect"
  xbps-rindex -a "${repo_dir}/iana-etc-20230929_1.noarch.xbps"
  touch "${build_dir}/.iana_etc_packaged"
fi

# Build glibc

if ! [ -f "${build_dir}/.glibc_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/glibc-2.38.tar.xz"
  mv "glibc-2.38" "glibc-src"
  patch -Np1 -d "${build_dir}/glibc-src" -i "/var/lfs/sources/glibc-2.38-fhs-1.patch"
  patch -Np1 -d "${build_dir}/glibc-src" -i "/var/lfs/sources/glibc-2.38-upstream_fixes-3.patch"
  sed '/test-installation/s@$(PERL)@echo not running@' -i "${build_dir}/glibc-src/Makefile"
  touch "${build_dir}/.glibc_prepared"
fi

if ! [ -f "${build_dir}/.glibc_configured" ]; then
  mkdir -p "${build_dir}/glibc-build"
  echo "rootsbindir=/usr/sbin" >"${build_dir}/glibc-build/configparms"
  cd "${build_dir}/glibc-build"
  "${build_dir}/glibc-src/configure" \
    --prefix=/usr \
    --disable-werror \
    --disable-nscd \
    --enable-kernel=4.14 \
    --enable-stack-protector=strong \
    --with-headers=/usr/include \
    libc_cv_slibdir=/usr/lib
  touch "${build_dir}/.glibc_configured"
fi

if ! [ -f "${build_dir}/.glibc_built" ]; then
  cd "${build_dir}/glibc-build"
  make -j
  touch "${build_dir}/.glibc_built"
fi

if ! [ -f "${build_dir}/.glibc_installed" ]; then
  mkdir -p "${build_dir}/glibc-collect"
  cd "${build_dir}/glibc-build"
  make DESTDIR="${build_dir}/glibc-collect" install
  make -C "${build_dir}/glibc-src/localedata" \
    objdir="${build_dir}/glibc-build" \
    DESTDIR="${build_dir}/glibc-collect" \
    install-locale-files -j
  # TODO: Add locale-gen
  sed -e '1,3d' -e 's|/| |g' -e 's| \\||g' \
    "${build_dir}/glibc-src/localedata/SUPPORTED" >"${build_dir}/glibc-collect/usr/share/i18n/SUPPORTED"
  rm -f "${build_dir}/glibc-collect/etc/ld.so.cache"
  install -dm755 "${build_dir}/glibc-collect/usr/lib"/{locale,systemd/system,tmpfiles.d}
  install -m644 "${build_dir}/glibc-src/posix/gai.conf" "${build_dir}/glibc-collect/etc/gai.conf"
  touch "${build_dir}/.glibc_installed"
fi

if ! [ -f "${build_dir}/.glibc_packaged" ]; then
  cd "${repo_dir}"
  xbps-create \
    -A x86_64 \
    -n glibc-2.38_1 \
    -s "GNU C Library" \
    "${build_dir}/glibc-collect"
  xbps-rindex -a "${repo_dir}/glibc-2.38_1.x86_64.xbps"
  touch "${build_dir}/.glibc_packaged"
fi

# Build zlib

if ! [ -f "${build_dir}/.zlib_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/zlib-1.3.tar.gz"
  mv "zlib-1.3" "zlib-src"
  touch "${build_dir}/.zlib_prepared"
fi

if ! [ -f "${build_dir}/.zlib_configured" ]; then
  mkdir -p "${build_dir}/zlib-build"
  cd "${build_dir}/zlib-build"
  "${build_dir}/zlib-src/configure" \
    --prefix=/usr
  touch "${build_dir}/.zlib_configured"
fi

if ! [ -f "${build_dir}/.zlib_built" ]; then
  cd "${build_dir}/zlib-build"
  make -j
  touch "${build_dir}/.zlib_built"
fi

if ! [ -f "${build_dir}/.zlib_installed" ]; then
  mkdir -p "${build_dir}/zlib-collect"
  cd "${build_dir}/zlib-build"
  make DESTDIR="${build_dir}/zlib-collect" install
  rm -f "${build_dir}/zlib-collect/usr/lib/libz.a"
  touch "${build_dir}/.zlib_installed"
fi

if ! [ -f "${build_dir}/.zlib_packaged" ]; then
  cd "${repo_dir}"
  xbps-create \
    -A x86_64 \
    -n zlib-1.3_1 \
    -s "Compression library implementing the deflate compression method found in gzip" \
    "${build_dir}/zlib-collect"
  xbps-rindex -a "${repo_dir}/zlib-1.3_1.x86_64.xbps"
  touch "${build_dir}/.zlib_packaged"
fi

# Build bzip2

if ! [ -f "${build_dir}/.bzip2_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/bzip2-1.0.8.tar.gz"
  mv "bzip2-1.0.8" "bzip2-src"
  patch -Np1 -d "bzip2-src" -i "/var/lfs/sources/bzip2-1.0.8-install_docs-1.patch"
  sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' "${build_dir}/bzip2-src/Makefile"
  sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" "${build_dir}/bzip2-src/Makefile"
  touch "${build_dir}/.bzip2_prepared"
fi

if ! [ -f "${build_dir}/.bzip2_built" ]; then
  cd "${build_dir}/bzip2-src"
  make -f Makefile-libbz2_so
  make clean
  make -j
  touch "${build_dir}/.bzip2_built"
fi

if ! [ -f "${build_dir}/.bzip2_installed" ]; then
  cd "${build_dir}/bzip2-src"
  make PREFIX="${build_dir}/bzip2-collect/usr" install
  cp -a "${build_dir}/bzip2-src"/libbz2.so.* "${build_dir}/bzip2-collect/usr/lib"
  cp bzip2-shared "${build_dir}/bzip2-collect/usr/bin/bzip2"
  ln -sf bzip2 "${build_dir}/bzip2-collect/usr/bin/bzcat"
  ln -sf bzip2 "${build_dir}/bzip2-collect/usr/bin/bunzip2"
  ln -sf libbz2.so.1.0.8 "${build_dir}/bzip2-collect/usr/lib/libbz2.so"
  rm -f "${build_dir}/bzip2-collect/usr/lib/libbz2.a"
  touch "${build_dir}/.bzip2_installed"
fi

if ! [ -f "${build_dir}/.bzip2_packaged" ]; then
  cd "${repo_dir}"
  xbps-create \
    -A x86_64 \
    -n bzip2-1.0.8_1 \
    -s "A high-quality data compressor" \
    "${build_dir}/bzip2-collect"
  xbps-rindex -a "${repo_dir}/bzip2-1.0.8_1.x86_64.xbps"
  touch "${build_dir}/.bzip2_packaged"
fi

# Build xz

if ! [ -f "${build_dir}/.xz_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/xz-5.4.4.tar.xz"
  mv "xz-5.4.4" "xz-src"
  touch "${build_dir}/.xz_prepared"
fi

if ! [ -f "${build_dir}/.xz_configured" ]; then
  mkdir -p "${build_dir}/xz-build"
  cd "${build_dir}/xz-build"
  "${build_dir}/xz-src/configure" \
    --prefix=/usr \
    --disable-static \
    --docdir=/usr/share/doc/xz-5.4.4
  touch "${build_dir}/.xz_configured"
fi

if ! [ -f "${build_dir}/.xz_built" ]; then
  cd "${build_dir}/xz-build"
  make -j
  touch "${build_dir}/.xz_built"
fi

if ! [ -f "${build_dir}/.xz_installed" ]; then
  mkdir -p "${build_dir}/xz-collect"
  cd "${build_dir}/xz-build"
  make DESTDIR="${build_dir}/xz-collect" install
  touch "${build_dir}/.xz_installed"
fi

if ! [ -f "${build_dir}/.xz_packaged" ]; then
  cd "${repo_dir}"
  xbps-create \
    -A x86_64 \
    -n xz-5.4.4_1 \
    -s "Utilities for managing LZMA compressed files" \
    "${build_dir}/xz-collect"
  xbps-rindex -a "${repo_dir}/xz-5.4.4_1.x86_64.xbps"
  touch "${build_dir}/.xz_packaged"
fi

# Build zstd

if ! [ -f "${build_dir}/.zstd_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/zstd-1.5.5.tar.gz"
  mv "zstd-1.5.5" "zstd-src"
  touch "${build_dir}/.zstd_prepared"
fi

if ! [ -f "${build_dir}/.zstd_built" ]; then
  mkdir -p "${build_dir}/zstd-collect"
  cd "${build_dir}/zstd-src"
  make prefix=/usr -j
  touch "${build_dir}/.zstd_built"
fi

if ! [ -f "${build_dir}/.zstd_installed" ]; then
  cd "${build_dir}/zstd-src"
  make prefix="${build_dir}/zstd-collect/usr" install
  touch "${build_dir}/.zstd_installed"
fi

if ! [ -f "${build_dir}/.zstd_packaged" ]; then
  cd "${repo_dir}"
  xbps-create \
    -A x86_64 \
    -n zstd-1.5.5_1 \
    -s "Fast real-time compression algorithm" \
    "${build_dir}/zstd-collect"
  xbps-rindex -a "${repo_dir}/zstd-1.5.5_1.x86_64.xbps"
  touch "${build_dir}/.zstd_packaged"
fi

# Build file

if ! [ -f "${build_dir}/.file_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/file-5.45.tar.gz"
  mv "file-5.45" "file-src"
  touch "${build_dir}/.file_prepared"
fi

if ! [ -f "${build_dir}/.file_configured" ]; then
  mkdir -p "${build_dir}/file-build"
  cd "${build_dir}/file-build"
  "${build_dir}/file-src/configure" \
    --prefix=/usr
  touch "${build_dir}/.file_configured"
fi

if ! [ -f "${build_dir}/.file_built" ]; then
  cd "${build_dir}/file-build"
  make -j
  touch "${build_dir}/.file_built"
fi

if ! [ -f "${build_dir}/.file_installed" ]; then
  mkdir -p "${build_dir}/file-collect"
  cd "${build_dir}/file-build"
  make DESTDIR="${build_dir}/file-collect" install
  touch "${build_dir}/.file_installed"
fi

if ! [ -f "${build_dir}/.file_packaged" ]; then
  cd "${repo_dir}"
  xbps-create \
    -A x86_64 \
    -n file-5.45_1 \
    -s "File type identification utility" \
    "${build_dir}/file-collect"
  xbps-rindex -a "${repo_dir}/file-5.45_1.x86_64.xbps"
  touch "${build_dir}/.file_packaged"
fi

# Build readline

if ! [ -f "${build_dir}/.readline_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/readline-8.2.tar.gz"
  mv "readline-8.2" "readline-src"
  sed -i '/MV.*old/d' "${build_dir}/readline-src/Makefile.in"
  sed -i '/{OLDSUFF}/c:' "${build_dir}/readline-src/support/shlib-install"
  patch -Np1 -d "${build_dir}/readline-src" -i "/var/lfs/sources/readline-8.2-upstream_fix-1.patch"
  touch "${build_dir}/.readline_prepared"
fi

if ! [ -f "${build_dir}/.readline_configured" ]; then
  mkdir -p "${build_dir}/readline-build"
  cd "${build_dir}/readline-build"
  "${build_dir}/readline-src/configure" \
    --prefix=/usr \
    --with-curses \
    --disable-static \
    --docdir=/usr/share/doc/readline-8.2
  touch "${build_dir}/.readline_configured"
fi

if ! [ -f "${build_dir}/.readline_built" ]; then
  cd "${build_dir}/readline-build"
  make SHLIB_LIBS="-lncursesw" -j
  touch "${build_dir}/.readline_built"
fi

if ! [ -f "${build_dir}/.readline_installed" ]; then
  mkdir -p "${build_dir}/readline-collect"
  cd "${build_dir}/readline-build"
  make SHLIB_LIBS="-lncursesw" DESTDIR="${build_dir}/readline-collect" install
  install -m644 "${build_dir}/readline-src/doc"/*.{ps,pdf,html,dvi} "${build_dir}/readline-collect/usr/share/doc/readline-8.2"
  touch "${build_dir}/.readline_installed"
fi

if ! [ -f "${build_dir}/.readline_packaged" ]; then
  cd "${repo_dir}"
  xbps-create \
    -A x86_64 \
    -n readline-8.2_1 \
    -s "GNU readline library" \
    "${build_dir}/readline-collect"
  xbps-rindex -a "${repo_dir}/readline-8.2_1.x86_64.xbps"
  touch "${build_dir}/.readline_packaged"
fi

# Build m4

if ! [ -f "${build_dir}/.m4_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/m4-1.4.19.tar.xz"
  mv "m4-1.4.19" "m4-src"
  touch "${build_dir}/.m4_prepared"
fi

if ! [ -f "${build_dir}/.m4_configured" ]; then
  mkdir -p "${build_dir}/m4-build"
  cd "${build_dir}/m4-build"
  "${build_dir}/m4-src/configure" \
    --prefix=/usr
  touch "${build_dir}/.m4_configured"
fi

if ! [ -f "${build_dir}/.m4_built" ]; then
  cd "${build_dir}/m4-build"
  make -j
  touch "${build_dir}/.m4_built"
fi

if ! [ -f "${build_dir}/.m4_installed" ]; then
  mkdir -p "${build_dir}/m4-collect"
  cd "${build_dir}/m4-build"
  make DESTDIR="${build_dir}/m4-collect" install
  touch "${build_dir}/.m4_installed"
fi

if ! [ -f "${build_dir}/.m4_packaged" ]; then
  cd "${repo_dir}"
  xbps-create \
    -A x86_64 \
    -n m4-1.4.19_1 \
    -s "GNU macro processor" \
    "${build_dir}/m4-collect"
  xbps-rindex -a "${repo_dir}/m4-1.4.19_1.x86_64.xbps"
  touch "${build_dir}/.m4_packaged"
fi

# Build bc

if ! [ -f "${build_dir}/.bc_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/bc-6.7.0.tar.xz"
  mv "bc-6.7.0" "bc-src"
  touch "${build_dir}/.bc_prepared"
fi

if ! [ -f "${build_dir}/.bc_configured" ]; then
  mkdir -p "${build_dir}/bc-build"
  cd "${build_dir}/bc-build"
  CC=gcc "${build_dir}/bc-src/configure" \
    --prefix=/usr \
    --enable-readline \
    -O3
  touch "${build_dir}/.bc_configured"
fi

if ! [ -f "${build_dir}/.bc_built" ]; then
  cd "${build_dir}/bc-build"
  make -j
  touch "${build_dir}/.bc_built"
fi

if ! [ -f "${build_dir}/.bc_installed" ]; then
  mkdir -p "${build_dir}/bc-collect"
  cd "${build_dir}/bc-build"
  make DESTDIR="${build_dir}/bc-collect" install
  touch "${build_dir}/.bc_installed"
fi

if ! [ -f "${build_dir}/.bc_packaged" ]; then
  cd "${repo_dir}"
  xbps-create \
    -A x86_64 \
    -n bc-6.7.0_1 \
    -s "An arbitrary precision numeric processing language" \
    "${build_dir}/bc-collect"
  xbps-rindex -a "${repo_dir}/bc-6.7.0_1.x86_64.xbps"
  touch "${build_dir}/.bc_packaged"
fi

# Build flex

if ! [ -f "${build_dir}/.flex_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/flex-2.6.4.tar.gz"
  mv "flex-2.6.4" "flex-src"
  touch "${build_dir}/.flex_prepared"
fi

if ! [ -f "${build_dir}/.flex_configured" ]; then
  mkdir -p "${build_dir}/flex-build"
  cd "${build_dir}/flex-build"
  "${build_dir}/flex-src/configure" \
    --prefix=/usr \
    --docdir=/usr/share/doc/flex-2.6.4 \
    --disable-static
  touch "${build_dir}/.flex_configured"
fi

if ! [ -f "${build_dir}/.flex_built" ]; then
  cd "${build_dir}/flex-build"
  make -j
  touch "${build_dir}/.flex_built"
fi

if ! [ -f "${build_dir}/.flex_installed" ]; then
  mkdir -p "${build_dir}/flex-collect"
  cd "${build_dir}/flex-build"
  make DESTDIR="${build_dir}/flex-collect" install
  ln -s flex "${build_dir}/flex-collect/usr/bin/lex"
  ln -s flex.1 "${build_dir}/flex-collect/usr/share/man/man1/lex.1"
  touch "${build_dir}/.flex_installed"
fi

if ! [ -f "${build_dir}/.flex_packaged" ]; then
  cd "${repo_dir}"
  xbps-create \
    -A x86_64 \
    -n flex-2.6.4_1 \
    -s "Fast lexical analyzer generator" \
    "${build_dir}/flex-collect"
  xbps-rindex -a "${repo_dir}/flex-2.6.4_1.x86_64.xbps"
  touch "${build_dir}/.flex_packaged"
fi


