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

# Fresh build folder with this repo's live-build config. live-build's download
# cache is kept between builds to save time.
CACHE_KEEP="${WORK}.cache"
if [[ -d "${WORK}" ]]; then
  (cd "${WORK}" && lb clean >/dev/null 2>&1 || true)
  rm -rf "${CACHE_KEEP}"
  [[ -d "${WORK}/cache" ]] && mv "${WORK}/cache" "${CACHE_KEEP}"
  rm -rf "${WORK}"
fi
mkdir -p "${WORK}"
cp -a "${HERE}/config" "${WORK}/"
[[ -d "${CACHE_KEEP}" ]] && mv "${CACHE_KEEP}" "${WORK}/cache"

# Live ISO boot menu (BIOS and UEFI): ETC's background instead of live-build's
# Debian splash. live-build uses these instead of rendering its splash.svg.
mkdir -p "${WORK}/config/bootloaders/syslinux_common"
cp "${REPO}/logos/emcomm-tools-boot-640x480.png" "${WORK}/config/bootloaders/syslinux_common/splash.png"
cp "${REPO}/logos/emcomm-tools-boot-800x600.png" "${WORK}/config/bootloaders/syslinux_common/splash800x600.png"

# BIOS installs: grub-pc conflicts with grub-efi-amd64, so it can't go in
# installer.list.binary. Its .debs go into the ISO's package pool through the
# 0910-grub-pc-pool binary hook.
mkdir -p "${WORK}/config/grub-pc"
apt-get update -qq
(cd "${WORK}/config/grub-pc" && apt-get download grub-pc grub-pc-bin)

# The repository, for the chroot hook (removed again by the hook). Only files
# git tracks (plus .git, for the release tag), so untracked files never reach
# the build. Uncommitted edits to tracked files are included: build releases
# from a clean checkout.
if [[ -n "$(git -C "${REPO}" status --porcelain --untracked-files=no)" ]]; then
  echo "WARNING: ${REPO} has uncommitted changes; they will be in the ISO."
fi
# xara isn't built into the ISO, so a xara-*.tar.gz in scripts/ is not copied.
mkdir -p "${WORK}/config/includes.chroot/opt/emcomm-tools-os-community"
{ git -C "${REPO}" ls-files -z; printf '.git\0'; } \
  | tar -C "${REPO}" --null -T - -cf - \
  | tar -C "${WORK}/config/includes.chroot/opt/emcomm-tools-os-community" -xf -
chmod 755 "${WORK}"/config/hooks/normal/*.hook.* \
          "${WORK}"/config/includes.chroot/usr/local/bin/* \
          "${WORK}"/config/includes.chroot/usr/local/sbin/* \
          "${WORK}"/config/includes.chroot/usr/lib/live/config/*

# Pass ET_RELEASE into the chroot hook.
if [[ -n "${ET_RELEASE:-}" ]]; then
  sed -i "s/^set -u$/set -u\nexport ET_RELEASE='${ET_RELEASE}'/" \
    "${WORK}/config/hooks/normal/0900-emcomm-tools.hook.chroot"
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
