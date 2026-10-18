#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}"

apt-get update -qq
apt-get install -y --no-install-recommends \
  busybox-static cpio gzip grub-pc-bin mtools xorriso linux-image-amd64 >/dev/null

rm -rf build/.rootfs build/iso build/iso-smoke
rm -f build/miloOS.iso build/miloOS-smoke.iso build/miloOS-BETA.iso build/miloOS-BETA-smoke.iso
mkdir -p build/.rootfs/{bin,dev,etc,proc,sys,tmp,root,run} \
  build/.rootfs/usr/share/backgrounds build/iso/boot/grub
chmod 1777 build/.rootfs/tmp

cp assets/miloos-wallpaper.svg build/.rootfs/usr/share/backgrounds/miloos-wallpaper.svg

cp "$(command -v busybox)" build/.rootfs/bin/busybox
for applet in sh mount umount cat dmesg echo grep hostname ls mkdir poweroff \
              reboot sleep uname clear; do
  ln -sf busybox "build/.rootfs/bin/$applet"
done

cat > build/.rootfs/init <<'INIT'
#!/bin/busybox sh
set -eu

mount -t proc  proc  /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
hostname miloOS

echo
echo "  miloOS - minimal console Linux"
echo "  kernel: $(uname -r)"
echo

if grep -q 'miloos.smoke=1' /proc/cmdline; then
  echo 'miloOS: smoke test OK'
  poweroff -f 2>/dev/null || reboot -f
fi

echo 'Type commands in the shell; poweroff -f shuts down.'
exec /bin/sh
INIT
chmod 755 build/.rootfs/init

cat > build/.rootfs/etc/motd <<'MOTD'
Welcome to miloOS.
MOTD

printf '%s\n' 'NAME=miloOS' 'ID=miloos' 'VERSION=0.1.0' > build/.rootfs/etc/os-release

# cpio stores each source file's mtime in the initramfs. Normalize all
# metadata so the same inputs produce the same archive when SOURCE_DATE_EPOCH
# is fixed (the default is Unix epoch 0).
find build/.rootfs -exec touch -h --date="@${SOURCE_DATE_EPOCH}" {} +

(
  cd build/.rootfs
  find . -print0 | sort -z | cpio --null --create --format=newc --reproducible --quiet | gzip -9 > ../initramfs.gz
)

KERNEL=$(find /boot -maxdepth 1 -type f -name 'vmlinuz-*' | sort -V | tail -n 1)
test -n "$KERNEL"
cp "$KERNEL" build/vmlinuz

cp build/vmlinuz build/iso/boot/vmlinuz
cp build/initramfs.gz build/iso/boot/initramfs.gz
cat > build/iso/boot/grub/grub.cfg <<'GRUB'
set timeout=0
set default=0
serial --unit=0 --speed=115200
terminal_input console serial
terminal_output console serial
menuentry "miloOS" {
  linux /boot/vmlinuz console=tty0 loglevel=4
  initrd /boot/initramfs.gz
}
GRUB

grub-mkrescue -o build/miloOS-BETA.iso build/iso >/dev/null 2>&1

# A separate image carries a one-shot kernel argument and is used only by the
# automated boot smoke test. The normal image always leaves the shell running.
cp -a build/iso build/iso-smoke
sed -i 's/console=tty0 loglevel=4/console=tty0 console=ttyS0,115200n8 loglevel=4 miloos.smoke=1/' build/iso-smoke/boot/grub/grub.cfg
grub-mkrescue -o build/miloOS-BETA-smoke.iso build/iso-smoke >/dev/null 2>&1

{
  echo 'miloOS-BETA 0.1.0'
  echo "kernel=$KERNEL"
  echo "kernel_version=$(basename "$KERNEL" | sed 's/^vmlinuz-//')"
  sha256sum build/miloOS-BETA.iso build/miloOS-BETA-smoke.iso build/vmlinuz build/initramfs.gz
} > build/manifest.txt

rm -rf build/.rootfs build/iso build/iso-smoke
if [ -n "${HOST_UID:-}" ] && [ -n "${HOST_GID:-}" ]; then
  chown -R "$HOST_UID:$HOST_GID" build
fi
echo 'Built build/miloOS-BETA.iso'
