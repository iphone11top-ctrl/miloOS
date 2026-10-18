#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
mkdir -p "$ROOT/build"

# The build runs in a disposable root container, so host packages are not
# modified. It writes output with the invoking user's ownership.
exec docker run --rm --platform linux/amd64 \
  -e SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}" \
  -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  -v "$ROOT:/src" -w /src debian:13-slim \
  bash /src/tools/build-in-container.sh
