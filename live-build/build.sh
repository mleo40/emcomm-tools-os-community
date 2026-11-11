#!/bin/bash
#
# Date    : 11 November 2026
# Purpose : Build the EmComm Tools ISO (Debian 12 + ETC) with live-build.
#
# Usage   : sudo ./build.sh
#
# Run on a Debian 12 machine (a VM is fine) with about 60 GB free and internet.
# The build happens in a fresh chroot, so nothing from this machine's users
# ends up in the ISO.
#
# Environment:
#   ET_WORK_DIR  build folder (default /var/tmp/etc-live-build), emptied first
#   ET_RELEASE   release name shown by et-system-info (default: from git tag)
#
# Output: emcomm-tools-os-community-<date>.iso and build.log in ET_WORK_DIR.

set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  exec sudo --preserve-env=ET_WORK_DIR,ET_RELEASE "$(readlink -f "$0")" "$@"
fi

HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
REPO="$(cd "${HERE}/.." && pwd)"
WORK="${ET_WORK_DIR:-/var/tmp/etc-live-build}"
ISO_NAME="emcomm-tools-os-community-$(date +%Y%m%d)"

command -v lb >/dev/null || { apt-get update && apt-get install -y live-build; }

# Fresh build folder with this repo's live-build config.
if [[ -d "${WORK}" ]]; then
  (cd "${WORK}" && lb clean --purge >/dev/null 2>&1 || true)
  rm -rf "${WORK}"
fi
mkdir -p "${WORK}"
cp -a "${HERE}/config" "${WORK}/"

# The repository, for the chroot hook (removed again by the hook). Only files
# git tracks (plus .git, for the release tag), so untracked files never reach
# the build. Uncommitted edits to tracked files are included: build releases
# from a clean checkout.
if [[ -n "$(git -C "${REPO}" status --porcelain --untracked-files=no)" ]]; then
  echo "WARNING: ${REPO} has uncommitted changes; they will be in the ISO."
fi
# Also the optional xara source package, if provided (see scripts/xara.md).
mkdir -p "${WORK}/config/includes.chroot/root/etc-build"
{ git -C "${REPO}" ls-files -z; printf '.git\0'
  (cd "${REPO}" && find scripts -maxdepth 1 -name 'xara-*.tar.gz' -print0); } \
  | tar -C "${REPO}" --null -T - -cf - \
  | tar -C "${WORK}/config/includes.chroot/root/etc-build" -xf -
chmod 755 "${WORK}"/config/hooks/normal/*.hook.chroot \
          "${WORK}"/config/includes.chroot/usr/local/bin/*

# Pass ET_RELEASE into the chroot hook.
if [[ -n "${ET_RELEASE:-}" ]]; then
  sed -i "s/^set -u$/set -u\nexport ET_RELEASE='${ET_RELEASE}'/" \
    "${WORK}/config/hooks/normal/9000-emcomm-tools.hook.chroot"
fi

cd "${WORK}"

lb config \
  --distribution bookworm \
  --archive-areas "main contrib non-free non-free-firmware" \
  --security true \
  --updates true \
  --debian-installer none \
  --binary-images iso-hybrid \
  --uefi-secure-boot enable \
  --memtest none \
  --firmware-binary true \
  --firmware-chroot true \
  --iso-application "EmComm Tools OS Community" \
  --iso-publisher "EmComm Tools" \
  --iso-volume "EmComm Tools" \
  --image-name "${ISO_NAME}" \
  --bootappend-live "boot=live components quiet splash live-config.hostname=emcomm-tools live-config.user-default-groups=audio,cdrom,dip,floppy,video,plugdev,netdev,bluetooth,scanner,lpadmin,dialout,tty,users,sudo,et-data"

lb build 2>&1 | tee build.log

ISO="$(ls -1t "${WORK}"/*.iso 2>/dev/null | head -1 || true)"
if [[ -z "${ISO}" ]]; then
  echo "No ISO was produced. See ${WORK}/build.log."
  exit 1
fi

echo
grep -E '^=== (EmComm Tools build|Failed steps)' build.log || true
echo "ISO: ${ISO}"
ls -lh "${ISO}"
