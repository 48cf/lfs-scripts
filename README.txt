How to build:

- Run ./tools/make_image.sh as root
- Run ./tools/mount.sh as root
- Run ./tools/make_dirs.sh as root
- Run ./download_sources.sh
- Run ./build_cross.sh
- Run ./tools/prepare_for_chroot.sh as root
- Run ./tools/chroot.sh as root

Inside chroot:

- Run /var/lfs/make_base_files.sh
- Run /var/lfs/build_temp.sh (preferably in /root)
