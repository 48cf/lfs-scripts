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

# Build which

if ! [ -f "${build_dir}/.which_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/which-2.21.tar.gz"
  mv "which-2.21" "which-src"
  touch "${build_dir}/.which_prepared"
fi

if ! [ -f "${build_dir}/.which_configured" ]; then
  mkdir -p "${build_dir}/which-build"
  cd "${build_dir}/which-build"
  "${build_dir}/which-src/configure" \
    --prefix=/usr
  touch "${build_dir}/.which_configured"
fi

if ! [ -f "${build_dir}/.which_built" ]; then
  cd "${build_dir}/which-build"
  make -j
  touch "${build_dir}/.which_built"
fi

if ! [ -f "${build_dir}/.which_installed" ]; then
  cd "${build_dir}/which-build"
  make install
  touch "${build_dir}/.which_installed"
fi

# Build pkgconf

if ! [ -f "${build_dir}/.pkgconf_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/pkgconf-2.0.3.tar.xz"
  mv "pkgconf-2.0.3" "pkgconf-src"
  sed -i 's/str\(cmp.*package\)/strn\1, strlen(pkg->why)/' "${build_dir}/pkgconf-src/cli/main.c"
  touch "${build_dir}/.pkgconf_prepared"
fi

if ! [ -f "${build_dir}/.pkgconf_configured" ]; then
  mkdir -p "${build_dir}/pkgconf-build"
  cd "${build_dir}/pkgconf-build"
  "${build_dir}/pkgconf-src/configure" \
    --prefix=/usr \
    --disable-static \
    --docdir=/usr/share/doc/pkgconf-2.0.3
  touch "${build_dir}/.pkgconf_configured"
fi

if ! [ -f "${build_dir}/.pkgconf_built" ]; then
  cd "${build_dir}/pkgconf-build"
  make -j
  touch "${build_dir}/.pkgconf_built"
fi

if ! [ -f "${build_dir}/.pkgconf_installed" ]; then
  cd "${build_dir}/pkgconf-build"
  make install
  ln -s pkgconf /usr/bin/pkg-config
  ln -s pkgconf.1 /usr/share/man/man1/pkg-config.1
  touch "${build_dir}/.pkgconf_installed"
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
  cd "${build_dir}/zlib-build"
  make install
  rm -f /usr/lib/libz.a
  touch "${build_dir}/.zlib_installed"
fi

# Build openssl

if ! [ -f "${build_dir}/.openssl_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/openssl-3.1.3.tar.gz"
  mv "openssl-3.1.3" "openssl-src"
  touch "${build_dir}/.openssl_prepared"
fi

if ! [ -f "${build_dir}/.openssl_configured" ]; then
  cd "${build_dir}/openssl-src"
  ./config \
    --prefix=/usr \
    --openssldir=/etc/ssl \
    --libdir=lib \
    shared \
    zlib-dynamic
  touch "${build_dir}/.openssl_configured"
fi

if ! [ -f "${build_dir}/.openssl_built" ]; then
  cd "${build_dir}/openssl-src"
  make -j
  touch "${build_dir}/.openssl_built"
fi

if ! [ -f "${build_dir}/.openssl_installed" ]; then
  cd "${build_dir}/openssl-src"
  sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' "${build_dir}/openssl-src/Makefile"
  make MANSUFFIX=ssl install
  mv /usr/share/doc/openssl /usr/share/doc/openssl-3.1.3
  cp -rf doc/* /usr/share/doc/openssl-3.1.3
  touch "${build_dir}/.openssl_installed"
fi

# Build zstd

if ! [ -f "${build_dir}/.zstd_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/zstd-1.5.5.tar.gz"
  mv "zstd-1.5.5" "zstd-src"
  touch "${build_dir}/.zstd_prepared"
fi

if ! [ -f "${build_dir}/.zstd_built" ]; then
  cd "${build_dir}/zstd-src"
  make prefix=/usr -j
  touch "${build_dir}/.zstd_built"
fi

if ! [ -f "${build_dir}/.zstd_installed" ]; then
  cd "${build_dir}/zstd-src"
  make prefix=/usr install
  rm /usr/lib/libzstd.a
  touch "${build_dir}/.zstd_installed"
fi

# Build libarchive

if ! [ -f "${build_dir}/.libarchive_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/libarchive-3.7.1.tar.xz"
  mv "libarchive-3.7.1" "libarchive-src"
  touch "${build_dir}/.libarchive_prepared"
fi

if ! [ -f "${build_dir}/.libarchive_configured" ]; then
  mkdir -p "${build_dir}/libarchive-build"
  cd "${build_dir}/libarchive-build"
  "${build_dir}/libarchive-src/configure" \
    --prefix=/usr \
    --disable-static
  touch "${build_dir}/.libarchive_configured"
fi

if ! [ -f "${build_dir}/.libarchive_built" ]; then
  cd "${build_dir}/libarchive-build"
  make -j
  touch "${build_dir}/.libarchive_built"
fi

if ! [ -f "${build_dir}/.libarchive_installed" ]; then
  cd "${build_dir}/libarchive-build"
  make install
  touch "${build_dir}/.libarchive_installed"
fi

# Build xbps

if ! [ -f "${build_dir}/.xbps_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/xbps-0.59.2.tar.gz"
  mv "xbps-0.59.2" "xbps-src"
  touch "${build_dir}/.xbps_prepared"
fi

if ! [ -f "${build_dir}/.xbps_configured" ]; then
  cd "${build_dir}/xbps-src"
  CFLAGS="-Wno-error" ./configure --prefix=/usr
  touch "${build_dir}/.xbps_configured"
fi

if ! [ -f "${build_dir}/.xbps_built" ]; then
  cd "${build_dir}/xbps-src"
  make -j
  touch "${build_dir}/.xbps_built"
fi

if ! [ -f "${build_dir}/.xbps_installed" ]; then
  cd "${build_dir}/xbps-src"
  make install
  touch "${build_dir}/.xbps_installed"
fi

# Build wget

if ! [ -f "${build_dir}/.wget_prepared" ]; then
  cd "${build_dir}"
  tar -xf "/var/lfs/sources/wget-1.21.4.tar.gz"
  mv "wget-1.21.4" "wget-src"
  touch "${build_dir}/.wget_prepared"
fi

if ! [ -f "${build_dir}/.wget_configured" ]; then
  mkdir -p "${build_dir}/wget-build"
  cd "${build_dir}/wget-build"
  "${build_dir}/wget-src/configure" \
    --prefix=/usr \
    --sysconfdir=/etc \
    --with-ssl=openssl
  touch "${build_dir}/.wget_configured"
fi

if ! [ -f "${build_dir}/.wget_built" ]; then
  cd "${build_dir}/wget-build"
  make -j
  touch "${build_dir}/.wget_built"
fi

if ! [ -f "${build_dir}/.wget_installed" ]; then
  cd "${build_dir}/wget-build"
  make install
  touch "${build_dir}/.wget_installed"
fi
