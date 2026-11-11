#!/bin/bash
#
# Date    : 11 November 2026
# Purpose : Install the OPTIONAL encryption tools (opt-in only).
#
# Installs:
#   - GNU Privacy Assistant (install-gpa.sh)
#   - Paranoia File & Text Encryption (install-pfte.sh)
#   - VeraCrypt (install-veracrypt.sh)
#   - steghide, gpg
#   - offline guides (gpg, steghide) and the AmRRON public key / GPG guide
#
# Usage:
#   sudo ./install-crypto.sh           Ask for confirmation, then install
#   sudo ./install-crypto.sh --yes     Install without asking
#   sudo ./install-crypto.sh --stage   Only copy this add-on to
#                                      /opt/emcomm-tools/add-ons/crypto
#                                      (used by install.sh; installs nothing)
#
# On a system installed from an ISO, run it from the staged copy:
#   cd /opt/emcomm-tools/add-ons/crypto/scripts && sudo ./install-crypto.sh

. ./env.sh
. ./functions.sh

exitIfNotRoot

ADDON_DIR="${ET_HOME}/add-ons/crypto"
CRYPTO_MARKER=/etc/emcomm-tools/crypto-enabled
OFFLINE_DIR=Desktop/offline

stage_addon() {
  et-log "Staging encryption add-on in ${ADDON_DIR} (not installing)..."
  mkdir -p "${ADDON_DIR}/scripts" "${ADDON_DIR}/overlay/opt/emcomm-tools/bin"
  cp -v \
    install-crypto.sh \
    install-gpa.sh \
    install-pfte.sh \
    install-veracrypt.sh \
    install-offline-lib.sh \
    install-offline-lib-crypto.json \
    env.sh \
    functions.sh \
    "${ADDON_DIR}/scripts/"
  cp -v -r crypto-docs "${ADDON_DIR}/scripts/"
  cp -v ../overlay/opt/emcomm-tools/bin/et-common "${ADDON_DIR}/overlay/opt/emcomm-tools/bin/"
}

if [[ "$1" == "--stage" ]]; then
  stage_addon
  exit 0
fi

if [[ "$1" != "--yes" ]]; then
  echo "This installs optional encryption tools: GNU Privacy Assistant,"
  echo "Paranoia File & Text Encryption, VeraCrypt, steghide, gpg and guides."
  read -r -p "Install optional encryption tools? [y/N] " ANSWER
  if [[ ! "${ANSWER}" =~ ^[Yy]$ ]]; then
    et-log "Encryption tools not installed."
    exit 0
  fi
fi

et-log "Installing optional encryption tools..."
mkdir -p "${ET_DIST_DIR}" "${ET_SRC_DIR}"

apt install \
  gpg \
  steghide \
  -y

./install-gpa.sh
./install-pfte.sh
./install-veracrypt.sh

et-log "Installing encryption guides..."
mkdir -p "/etc/skel/${OFFLINE_DIR}/crypto"
cp -v crypto-docs/* "/etc/skel/${OFFLINE_DIR}/crypto/"
./install-offline-lib.sh install-offline-lib-crypto.json

# Give the guides to the user running this too (new users get them from
# /etc/skel). Existing files are kept.
if [[ -n "${SUDO_USER}" && "${SUDO_USER}" != "root" ]]; then
  USER_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
  if [[ -d "${USER_HOME}" ]]; then
    mkdir -p "${USER_HOME}/${OFFLINE_DIR}"
    cp -a -n "/etc/skel/${OFFLINE_DIR}/." "${USER_HOME}/${OFFLINE_DIR}/"
    chown -R "${SUDO_USER}:${ET_GROUP}" "${USER_HOME}/${OFFLINE_DIR}"
  fi
fi

mkdir -p "$(dirname "${CRYPTO_MARKER}")"
date -u +"%Y-%m-%dT%H:%M:%SZ" > "${CRYPTO_MARKER}"

et-log "Optional encryption tools installed."
