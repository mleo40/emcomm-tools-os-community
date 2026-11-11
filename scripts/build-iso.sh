#!/bin/bash
#
# Date    : 11 November 2026
# Purpose : Build a bootable live ISO of this EmComm Tools system with
#           penguins-eggs. The ISO boots as a live system and can install
#           itself to disk with Calamares.
#
# Usage   : et-build-iso          (link created by install.sh)
#           sudo ./build-iso.sh   (from this folder)
#
# Two kinds of ISO:
#   1) Clean    - shareable; accounts, /home, Wi-Fi, SSH host keys and logs
#                 are left out. Live user is created from /etc/skel. The
#                 et-build-iso link is left out too (it points into /home).
#   2) Personal - a portable copy of YOUR system, including your account and
#                 data. Optionally encrypted with a passphrase (LUKS).
#
# Output  : /home/eggs/
#
# NOTE: penguins-eggs is pinned below. Its CLI and config change often, so test
#       a new version before bumping the pin.
set -e

# Work from this script's folder, even when started through the et-build-iso
# link: env.sh, functions.sh and ../overlay are found relative to it.
cd "$(dirname "$(readlink -f "$0")")"

# Ask for sudo instead of failing when run as a normal user.
if [[ ${EUID} -ne 0 ]]; then
  exec sudo "$(readlink -f "$0")" "$@"
fi

. ./env.sh
. ./functions.sh

EGGS_VERSION="26.10.30"
EGGS_ZIP="penguins-eggs-debian.zip"
EGGS_URL="https://github.com/pieroproietti/penguins-eggs/releases/download/v${EGGS_VERSION}/${EGGS_ZIP}"
EGGS_DIR=/etc/penguins-eggs.d
EGGS_OUT=/home/eggs
EXCLUDE_LIST="${EGGS_DIR}/custom.exclude.list"
EXCLUDE_BEGIN="# >>> emcomm-tools clean ISO >>>"
EXCLUDE_END="# <<< emcomm-tools clean ISO <<<"
CRYPTO_MARKER=/etc/emcomm-tools/crypto-enabled
BRANDING_SRC=../overlay/etc/calamares/branding/emcomm-tools

# ---------------------------------------------------------------------------
# Choose the kind of ISO
# ---------------------------------------------------------------------------
echo "Which ISO do you want to build?"
echo "  1) Clean system: ready to deploy for someone else (default)"
echo "  2) Personal system: your accounts, settings and files, portable to any machine"
read -r -p "Choice [1/2]: " CHOICE
[[ "${CHOICE}" == "2" ]] && MODE=personal || MODE=clean

# --anonymous: opt out of eggs' "anonymous census" telemetry (on by default).
EGGS_FLAGS=(--anonymous)
if [[ "${MODE}" == "personal" ]]; then
  echo
  echo "WARNING: a personal ISO contains your private data: Winlink/Pat"
  echo "credentials, GPG keys, Wi-Fi passwords, messages and files."
  echo "Anyone who has the ISO file has all of it. Do not share it."
  read -r -p "Continue? [y/N] " OK
  [[ "${OK}" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }

  read -r -p "Encrypt the ISO with a passphrase? [y/N] " ENCRYPT
  if [[ "${ENCRYPT}" =~ ^[Yy]$ ]]; then
    # Encrypted clone: keeps user data, asks for the passphrase at every boot.
    EGGS_FLAGS+=(--crypted)
  else
    EGGS_FLAGS+=(--clone)
  fi
  ISO_NAME="emcomm-tools-personal-$(hostname -s)-$(date +%Y%m%d)"
else
  ISO_NAME="emcomm-tools-os-community-$(date +%Y%m%d)"
  [[ -e "${CRYPTO_MARKER}" ]] && ISO_NAME="${ISO_NAME}-crypto"
fi

# ---------------------------------------------------------------------------
# Install penguins-eggs (pinned), Calamares and LUKS support
# ---------------------------------------------------------------------------
et-log "Installing ISO build dependencies..."
apt update
# cryptsetup: needed by the Calamares encryption checkbox and by --crypted.
apt install -y unzip calamares cryptsetup cryptsetup-initramfs busybox-static

INSTALLED_EGGS=$(dpkg-query -W -f='${Version}' penguins-eggs 2>/dev/null || true)
if [[ "${INSTALLED_EGGS}" != "${EGGS_VERSION}-1" ]]; then
  et-log "Installing penguins-eggs ${EGGS_VERSION}..."
  mkdir -p "${ET_DIST_DIR}"
  if [[ ! -e "${ET_DIST_DIR}/penguins-eggs-${EGGS_VERSION}.zip" ]]; then
    curl -fL -o "${ET_DIST_DIR}/penguins-eggs-${EGGS_VERSION}.zip" "${EGGS_URL}"
  fi
  TMP_DIR=$(mktemp -d)
  unzip -o -q "${ET_DIST_DIR}/penguins-eggs-${EGGS_VERSION}.zip" -d "${TMP_DIR}"
  apt install -y "${TMP_DIR}"/penguins-eggs_*_amd64.deb
  rm -rf "${TMP_DIR}"
fi

# The live session's "Install System" desktop launcher: eggs marks it trusted
# with 'yes', but GNOME's desktop icons extension (ding) only accepts 'true' and
# otherwise shows the launcher as broken (red X, file name instead of name).
TRUST_SCRIPT="${EGGS_DIR}/scripts/trust-desktop.sh"
if [[ -f "${TRUST_SCRIPT}" ]]; then
  sed -i 's/metadata::trusted yes/metadata::trusted true/' "${TRUST_SCRIPT}"
  grep -q 'metadata::trusted true' "${TRUST_SCRIPT}" \
    || et-log "WARNING: could not fix the live installer launcher in ${TRUST_SCRIPT}"
else
  et-log "WARNING: ${TRUST_SCRIPT} not found; check the live installer launcher"
fi

# ---------------------------------------------------------------------------
# Branding and installer settings
# ---------------------------------------------------------------------------
et-log "Installing EmComm Tools branding for the live ISO and Calamares..."
mkdir -p "${EGGS_DIR}/branding/calamares/branding" "${EGGS_DIR}/branding/livecd" \
         "${EGGS_DIR}/branding/calamares/modules"
cp -v -r "${BRANDING_SRC}/." "${EGGS_DIR}/branding/calamares/branding/"
# eggs installs these files into its own branding folder, named 'eggs', and sets
# 'branding: eggs'. Calamares stops with a fatal error unless componentName
# matches that folder name.
sed -i 's/^componentName:.*/componentName:  eggs/' \
  "${EGGS_DIR}/branding/calamares/branding/branding.desc"
convert ../logos/emcomm-tools-wallpaper.png -resize 640x480! \
  "${EGGS_DIR}/branding/livecd/splash.png"

# Users created by Calamares get the EmComm Tools groups. Calamares uses
# useradd, which ignores /etc/adduser.conf.
{
  echo "---"
  echo "defaultGroups:"
  for GROUP in ${ET_GROUP} $(sed -n 's/^EXTRA_GROUPS="\(.*\)"/\1/p' /etc/adduser.conf) sudo; do
    echo "    - name: ${GROUP}"
    echo "      must_exist: false"
    echo "      system: true"
  done
  echo "sudoersGroup: sudo"
  echo "setRootPassword: false"
} > "${EGGS_DIR}/branding/calamares/modules/users.conf"

# Clean ISOs: SSH host keys are left out, so make sure sshd gets new ones on
# first boot. (Does nothing while keys exist, including on this system.)
cat > /etc/systemd/system/et-ssh-keygen.service <<'EOF'
[Unit]
Description=Generate missing SSH host keys (EmComm Tools)
ConditionPathExistsGlob=!/etc/ssh/ssh_host_*_key
Before=ssh.service

[Service]
Type=oneshot
ExecStart=/usr/bin/ssh-keygen -A

[Install]
WantedBy=multi-user.target
EOF
systemctl enable et-ssh-keygen.service

# Users created by Calamares get et-data only as an extra group: Calamares runs
# 'useradd -U', which always creates a personal primary group. ETC expects
# et-data as the primary group (USERS_GID in /etc/adduser.conf) so files are
# shared. At boot, give et-data members et-data as their primary group and move
# their home's files from the personal group to et-data. Does nothing once set.
cat > /usr/local/sbin/et-fix-primary-group <<EOF
#!/bin/bash
# Installed by build-iso.sh. See et-fix-primary-group.service.
ET_GROUP=${ET_GROUP}
EOF
cat >> /usr/local/sbin/et-fix-primary-group <<'EOF'
ET_GID=$(getent group "${ET_GROUP}" | cut -d: -f3)
[[ -n "${ET_GID}" ]] || exit 0
getent passwd | while IFS=: read -r USER _ USER_UID USER_GID _ HOME_DIR _; do
  (( USER_UID >= 1000 && USER_UID < 60000 )) || continue
  [[ "${USER_GID}" == "${ET_GID}" ]] && continue
  id -nG "${USER}" | tr ' ' '\n' | grep -qx "${ET_GROUP}" || continue
  usermod -g "${ET_GROUP}" "${USER}"
  [[ -d "${HOME_DIR}" ]] && find "${HOME_DIR}" -xdev -gid "${USER_GID}" -exec chgrp -h "${ET_GROUP}" {} +
  logger -t et-fix-primary-group "Set primary group of ${USER} to ${ET_GROUP}"
done
EOF
chmod 755 /usr/local/sbin/et-fix-primary-group
cat > /etc/systemd/system/et-fix-primary-group.service <<'EOF'
[Unit]
Description=Give EmComm Tools users et-data as their primary group
Before=display-manager.service systemd-user-sessions.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/et-fix-primary-group

[Install]
WantedBy=multi-user.target
EOF
systemctl enable et-fix-primary-group.service

# ---------------------------------------------------------------------------
# What to leave out of the ISO
# ---------------------------------------------------------------------------
touch "${EXCLUDE_LIST}"
sed -i "/^${EXCLUDE_BEGIN}$/,/^${EXCLUDE_END}$/d" "${EXCLUDE_LIST}"
if [[ "${MODE}" == "clean" ]]; then
  cat >> "${EXCLUDE_LIST}" <<EOF
${EXCLUDE_BEGIN}
etc/NetworkManager/system-connections/*
etc/ssh/ssh_host_*
var/log/*.log
var/log/*.gz
var/log/*.[0-9]
var/log/journal/*
tmp/et/*
usr/local/bin/et-build-iso
${EXCLUDE_END}
EOF
fi

et-log "Cleaning apt cache..."
apt-get clean

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
et-log "Building ${MODE} ISO with: eggs remaster ${EGGS_FLAGS[*]}"
STARTED=$(date +%s)
eggs remaster "${EGGS_FLAGS[@]}"

NEWEST_ISO=$(find -L "${EGGS_OUT}" -maxdepth 1 -name '*.iso' -newermt "@${STARTED}" -printf '%T@ %p\n' 2>/dev/null \
  | sort -n | tail -1 | cut -d' ' -f2-)
if [[ -n "${NEWEST_ISO}" ]]; then
  mv -v "${NEWEST_ISO}" "${EGGS_OUT}/${ISO_NAME}.iso"
  et-log "ISO ready: ${EGGS_OUT}/${ISO_NAME}.iso"
else
  et-log "eggs finished, but no new ISO was found in ${EGGS_OUT}. Check the eggs output above."
  exit 1
fi
