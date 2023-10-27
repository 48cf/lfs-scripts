#!/bin/bash

set -e

if test $(id -u) -ne 0; then
  echo "this script must be ran as root"
  exit 1
fi

base_dir=$(pwd)
build_dir="${base_dir}/build"

if ! [ -d "${build_dir}" ]; then
  mkdir -p "${build_dir}"
fi

# Build gettext

if ! [ -f "${build_dir}/.gettext_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/gettext-0.22.3.tar.xz"
  mv "gettext-0.22.3" "gettext-src"
  touch "${build_dir}/.gettext_prepared"
fi

if ! [ -f "${build_dir}/.gettext_configured" ]; then
  mkdir -p "${build_dir}/gettext-build"
  cd "${build_dir}/gettext-build"
  "${build_dir}/gettext-src/configure" \
    --prefix=/usr
  touch "${build_dir}/.gettext_configured"
fi

if ! [ -f "${build_dir}/.gettext_built" ]; then
  cd "${build_dir}/gettext-build"
  make -j
  touch "${build_dir}/.gettext_built"
fi

if ! [ -f "${build_dir}/.gettext_installed" ]; then
  cp "${build_dir}/gettext-build/gettext-tools/src"/{msgfmt,msgmerge,xgettext} "/usr/bin"
  touch "${build_dir}/.gettext_installed"
fi

# Build bison

if ! [ -f "${build_dir}/.bison_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/bison-3.8.2.tar.xz"
  mv "bison-3.8.2" "bison-src"
  touch "${build_dir}/.bison_prepared"
fi

if ! [ -f "${build_dir}/.bison_configured" ]; then
  mkdir -p "${build_dir}/bison-build"
  cd "${build_dir}/bison-build"
  "${build_dir}/bison-src/configure" \
    --prefix=/usr \
    --docdir=/usr/share/doc/bison-3.8.2
  touch "${build_dir}/.bison_configured"
fi

if ! [ -f "${build_dir}/.bison_built" ]; then
  cd "${build_dir}/bison-build"
  make -j
  touch "${build_dir}/.bison_built"
fi

if ! [ -f "${build_dir}/.bison_installed" ]; then
  cd "${build_dir}/bison-build"
  make install
  touch "${build_dir}/.bison_installed"
fi

# Build perl

if ! [ -f "${build_dir}/.perl_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/perl-5.38.0.tar.xz"
  mv "perl-5.38.0" "perl-src"
  touch "${build_dir}/.perl_prepared"
fi

if ! [ -f "${build_dir}/.perl_configured" ]; then
  cd "${build_dir}/perl-src"
  sh Configure -des \
    -Dprefix=/usr \
    -Dvendorprefix=/usr \
    -Duseshrplib \
    -Dprivlib=/usr/lib/perl5/5.38/core_perl \
    -Darchlib=/usr/lib/perl5/5.38/core_perl \
    -Dsitelib=/usr/lib/perl5/5.38/site_perl \
    -Dsitearch=/usr/lib/perl5/5.38/site_perl \
    -Dvendorlib=/usr/lib/perl5/5.38/vendor_perl \
    -Dvendorarch=/usr/lib/perl5/5.38/vendor_perl
  touch "${build_dir}/.perl_configured"
fi

if ! [ -f "${build_dir}/.perl_built" ]; then
  cd "${build_dir}/perl-src"
  make -j
  touch "${build_dir}/.perl_built"
fi

if ! [ -f "${build_dir}/.perl_installed" ]; then
  cd "${build_dir}/perl-src"
  make install
  touch "${build_dir}/.perl_installed"
fi

# Build python

if ! [ -f "${build_dir}/.python_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/Python-3.11.5.tar.xz"
  mv "Python-3.11.5" "python-src"
  touch "${build_dir}/.python_prepared"
fi

if ! [ -f "${build_dir}/.python_configured" ]; then
  mkdir -p "${build_dir}/python-build"
  cd "${build_dir}/python-build"
  "${build_dir}/python-src/configure" \
    --prefix=/usr \
    --enable-shared \
    --without-ensurepip
  touch "${build_dir}/.python_configured"
fi

if ! [ -f "${build_dir}/.python_built" ]; then
  cd "${build_dir}/python-build"
  make -j
  touch "${build_dir}/.python_built"
fi

if ! [ -f "${build_dir}/.python_installed" ]; then
  cd "${build_dir}/python-build"
  make install
  touch "${build_dir}/.python_installed"
fi

# Build texinfo

if ! [ -f "${build_dir}/.texinfo_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/texinfo-7.0.3.tar.xz"
  mv "texinfo-7.0.3" "texinfo-src"
  touch "${build_dir}/.texinfo_prepared"
fi

if ! [ -f "${build_dir}/.texinfo_configured" ]; then
  mkdir -p "${build_dir}/texinfo-build"
  cd "${build_dir}/texinfo-build"
  "${build_dir}/texinfo-src/configure" \
    --prefix=/usr
  touch "${build_dir}/.texinfo_configured"
fi

if ! [ -f "${build_dir}/.texinfo_built" ]; then
  cd "${build_dir}/texinfo-build"
  make -j
  touch "${build_dir}/.texinfo_built"
fi

if ! [ -f "${build_dir}/.texinfo_installed" ]; then
  cd "${build_dir}/texinfo-build"
  make install
  touch "${build_dir}/.texinfo_installed"
fi

# Build util-linux

if ! [ -f "${build_dir}/.util-linux_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/util-linux-2.39.2.tar.xz"
  mv "util-linux-2.39.2" "util-linux-src"
  touch "${build_dir}/.util-linux_prepared"
fi

if ! [ -f "${build_dir}/.util-linux_configured" ]; then
  mkdir -p "${build_dir}/util-linux-build"
  cd "${build_dir}/util-linux-build"
  "${build_dir}/util-linux-src/configure" \
    ADJTIME_PATH=/var/lib/hwclock/adjtime \
    --docdir=/usr/share/doc/util-linux-2.39.2 \
    --libdir=/usr/lib \
    --runstatedir=/run \
    --disable-chfn-chsh \
    --disable-login \
    --disable-nologin \
    --disable-pylibmount \
    --disable-runuser \
    --disable-setpriv \
    --disable-static \
    --disable-su \
    --without-python
  touch "${build_dir}/.util-linux_configured"
fi

if ! [ -f "${build_dir}/.util-linux_built" ]; then
  cd "${build_dir}/util-linux-build"
  make -j
  touch "${build_dir}/.util-linux_built"
fi

if ! [ -f "${build_dir}/.util-linux_installed" ]; then
  cd "${build_dir}/util-linux-build"
  make install
  touch "${build_dir}/.util-linux_installed"
fi

# Clean up system

rm -rf /var/lfs/tools
rm -rf /usr/share/{info,man,doc}/*

find /usr/{lib,libexec} -name \*.la -delete
