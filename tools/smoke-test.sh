#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"
test -s build/miloOS-smoke.iso

set +e
output=$(docker run --rm --platform linux/amd64 -v "$ROOT/build:/images:ro" \
  debian:13-slim bash -eu -c '
    apt-get update -qq
    apt-get install -y --no-install-recommends -qq qemu-system-x86 >/dev/null
    timeout 45 qemu-system-x86_64 -cdrom /images/miloOS-smoke.iso -m 256 \
      -nographic -serial mon:stdio -no-reboot 2>&1
  ')
status=$?
set -e
printf '%s\n' "$output" | tee build/smoke.log

# QEMU may report a non-zero status when the guest powers itself off; the
# marker is the authoritative readiness assertion.
printf '%s\n' "$output" | grep -q 'miloOS: smoke test OK'
echo 'Smoke test passed.'
