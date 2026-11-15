#!/bin/bash
#
# Date    : 11 November 2026
# Purpose : Build the EmComm Tools ISO (Debian 12 + ETC) with live-build.
#
# Usage   : sudo ./build.sh
#
# Run on a Debian 12 machine (a VM is fine) with about 60 GB free and internet.
# The build happens in a fresh chroot, so nothing from this machine's users
# ends up in the ISO. It pauses in a root shell inside the ISO's system, like
# Cubic's terminal: run ./install.sh there, then exit to make the ISO.
#
# Environment:
#   ET_WORK_DIR  build folder (default /var/tmp/etc-live-build), emptied first
#
# The release name, ISO file name, volume ID and installer version come from
# the newest ETC tag on the checkout.
#
# Output: emcomm-tools-os-community-<tag date>-<release>-amd64.hybrid.iso and
# build.log in ET_WORK_DIR.

set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  exec sudo --preserve-env=ET_WORK_DIR "$(readlink -f "$0")" "$@"
fi

HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
REPO="$(cd "${HERE}/.." && pwd)"
WORK="${ET_WORK_DIR:-/var/tmp/etc-live-build}"

command -v lb >/dev/null || { apt-get update && apt-get install -y live-build; }

[[ -t 0 ]] || { echo "build.sh needs a terminal: it pauses for you to run install.sh."; exit 1; }

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

# Live ISO boot menu: ETC's background instead of live-build's splash.
mkdir -p "${WORK}/config/bootloaders/syslinux_common"
cp "${REPO}/logos/emcomm-tools-boot-640x480.png" "${WORK}/config/bootloaders/syslinux_common/splash.png"
cp "${REPO}/logos/emcomm-tools-boot-800x600.png" "${WORK}/config/bootloaders/syslinux_common/splash800x600.png"

# BIOS GRUB for offline installs (added to the pool by the 0910 hook).
mkdir -p "${WORK}/config/grub-pc"
apt-get update -qq
(cd "${WORK}/config/grub-pc" && apt-get download grub-pc grub-pc-bin)

# The repository for the chroot hook, which keeps it as a read-only copy.
# Only tracked files (plus .git, for the hook's cleanup); uncommitted edits to
# tracked files are included, so build releases from a clean checkout.
if [[ -n "$(git -C "${REPO}" status --porcelain --untracked-files=no)" ]]; then
  echo "WARNING: ${REPO} has uncommitted changes; they will be in the ISO."
fi
mkdir -p "${WORK}/config/includes.chroot/opt/emcomm-tools-os-community"
{ git -C "${REPO}" ls-files -z; printf '.git\0'; } \
  | tar -C "${REPO}" --null -T - -cf - \
  | tar -C "${WORK}/config/includes.chroot/opt/emcomm-tools-os-community" -xf -
# xara's source, if provided (see scripts/xara.md): install.sh builds it.
cp -v "${REPO}"/scripts/xara-*.tar.gz \
  "${WORK}/config/includes.chroot/opt/emcomm-tools-os-community/scripts/" 2>/dev/null || true
chmod 755 "${WORK}"/config/hooks/normal/*.hook.* \
          "${WORK}"/config/includes.chroot/usr/local/bin/* \
          "${WORK}"/config/includes.chroot/usr/local/sbin/* \
          "${WORK}"/config/includes.chroot/usr/lib/live/config/*

# Release values from the newest ETC tag, e.g.
# emcomm-tools-os-community-20261111-r7-build37: release ETC_R7_BUILD37,
# installer version "R7 Build37". A checkout past the tag adds its commit, and
# uncommitted changes add "modified", so test ISOs can't pass for the release.
GIT=(git -c safe.directory='*' -C "${REPO}")
TAG=$("${GIT[@]}" describe --tags --abbrev=0 --match 'emcomm-tools-os-community-*' 2>/dev/null || true)
TAG_DATE=$(echo "${TAG}" | sed -n 's/^emcomm-tools-os-community-\([0-9]\{8\}\)-.*/\1/p')
SLUG=$(echo "${TAG}" | sed 's/^emcomm-tools-os-community-[0-9]*-//')
SUFFIX=""
if [[ -z "${TAG}" || "$("${GIT[@]}" rev-parse HEAD)" != "$("${GIT[@]}" rev-list -n 1 "${TAG}")" ]]; then
  SUFFIX="-$("${GIT[@]}" rev-parse --short HEAD)"
fi
[[ -n "$("${GIT[@]}" status --porcelain --untracked-files=no)" ]] && SUFFIX="${SUFFIX}-modified"
[[ -z "${TAG}" ]] && { TAG_DATE=$(date +%Y%m%d); SLUG=dev; }
ET_RELEASE="ETC_$(echo "${SLUG}" | tr 'a-z-' 'A-Z_')${SUFFIX}"
ET_RELEASE_NAME="$(echo "${SLUG}" | sed 's/-/ /g; s/\b\(.\)/\u\1/g')${SUFFIX:+ (${SUFFIX#-})}"
ISO_NAME="emcomm-tools-os-community-${TAG_DATE}-${SLUG}${SUFFIX}"
ISO_VERSION="${TAG_DATE:0:4}.${TAG_DATE:4:2}.${TAG_DATE:6:2}.${SLUG}${SUFFIX}"
echo "Release: ${ET_RELEASE} (${ISO_NAME})"

sed -i "s/^set -u$/set -u\nexport ET_RELEASE='${ET_RELEASE}' ET_RELEASE_NAME='${ET_RELEASE_NAME}'/" \
  "${WORK}/config/hooks/normal/0900-emcomm-tools.hook.chroot"
sed -i "s/@ET_RELEASE@/${ET_RELEASE}/" "${WORK}/config/hooks/normal/0920-boot-menu.hook.binary"

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
  --iso-application "EmComm Tools OS Community ${ISO_VERSION}" \
  --iso-publisher "EmComm Tools" \
  --iso-volume "${ET_RELEASE:0:32}" \
  --image-name "${ISO_NAME}" \
  --bootappend-live "boot=live components quiet splash live-config.hostname=emcomm-tools live-config.user-default-groups=audio,cdrom,dip,floppy,video,plugdev,netdev,bluetooth,scanner,lpadmin,dialout,tty,users,sudo,et-data"

# script keeps the terminal for the build hook's shell and logs everything.
script -qec "lb build" build.log

ISO="$(ls -1t "${WORK}"/*.iso 2>/dev/null | head -1 || true)"
if [[ -z "${ISO}" ]]; then
  echo "No ISO was produced. See ${WORK}/build.log."
  exit 1
fi

echo
grep -E '^=== (EmComm Tools build|Failed steps)' build.log || true
echo "ISO: ${ISO}"
ls -lh "${ISO}"
