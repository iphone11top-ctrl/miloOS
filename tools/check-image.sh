#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"
for image in build/miloOS.iso build/miloOS-smoke.iso build/vmlinuz build/initramfs.gz build/manifest.txt; do
  test -s "$image"
done

docker run --rm --platform linux/amd64 -v "$ROOT:/src:ro" -w /src debian:13-slim \
  bash -eu -c '
    apt-get update -qq
    apt-get install -y --no-install-recommends -qq cpio file gzip >/dev/null
    file build/miloOS.iso build/miloOS-smoke.iso build/vmlinuz build/initramfs.gz
    gzip -t build/initramfs.gz
    mkdir -p /tmp/milo-check
    cd /tmp/milo-check
    gzip -dc /src/build/initramfs.gz | cpio -idm --quiet
    test -x init
    test -x bin/busybox
    grep -qx "NAME=miloOS" etc/os-release
    test -s usr/share/backgrounds/miloos-wallpaper.svg
  '

echo 'Image checks passed.'
