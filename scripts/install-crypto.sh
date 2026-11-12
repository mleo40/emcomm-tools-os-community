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
#   sudo ./install-crypto.sh --prepare Image builds (ET_BUILD): download the
#                                      packages, build GPA and download the
#                                      guides into the add-on, without
#                                      installing anything, for --offline
#   sudo ./install-crypto.sh --offline Install from what --prepare stored, with
#                                      no network (used by the ISO installer)
#
# On a system installed from an ISO, run it from the staged copy:
#   cd /opt/emcomm-tools/add-ons/crypto/scripts && sudo ./install-crypto.sh

# Work from this script's folder (the installer calls it by full path) and make
# sure the ETC commands (et-log) are found.
cd "$(dirname "$(readlink -f "$0")")"
export PATH="/opt/emcomm-tools/bin:${PATH}"

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

GPA_VERSION=0.11.1
PAYLOAD_DIR="${ADDON_DIR}/payload"

# Download everything the tools need into the add-on, and build GPA, without
# leaving any of it installed in the image.
prepare_offline() {
  et-log "Preparing encryption tools for offline install in ${PAYLOAD_DIR}..."
  mkdir -p "${PAYLOAD_DIR}/debs/partial" "${PAYLOAD_DIR}/offline/crypto"

  # Debian packages and the dependencies this image doesn't already have.
  apt-get install -y --download-only \
    -o Dir::Cache::archives="${PAYLOAD_DIR}/debs" \
    steghide pcscd
  rm -rf "${PAYLOAD_DIR}/debs/partial" "${PAYLOAD_DIR}/debs/lock"

  # PFTE and VeraCrypt .debs.
  ET_DOWNLOAD_ONLY="${PAYLOAD_DIR}/debs" ./install-pfte.sh
  ET_DOWNLOAD_ONLY="${PAYLOAD_DIR}/debs" ./install-veracrypt.sh

  # GPA is built from source: build it, pack it, then take it out of the image.
  ./install-gpa.sh
  tar -C /opt -czf "${PAYLOAD_DIR}/gpa-${GPA_VERSION}.tar.gz" "gpa-${GPA_VERSION}"
  stow -D -d /opt gpa -t /usr/local
  rm -rf "/opt/gpa" "/opt/gpa-${GPA_VERSION}" "${ET_SRC_DIR}/gpa-${GPA_VERSION}"

  # Guides and the AmRRON key, laid out as in Desktop/offline.
  cp -v crypto-docs/* "${PAYLOAD_DIR}/offline/crypto/"
  ./install-offline-lib.sh install-offline-lib-crypto.json "${PAYLOAD_DIR}/offline"

  et-log "Encryption tools prepared (not installed)."
}

# Install from the prepared payload. No network.
install_offline() {
  [[ -d "${PAYLOAD_DIR}" ]] || { et-log "No prepared payload in ${PAYLOAD_DIR}."; exit 1; }
  et-log "Installing optional encryption tools from ${PAYLOAD_DIR}..."
  # Local .debs only. (--no-download would refuse them: apt counts copying a
  # local file as a download.) Dependencies are all in debs/ or installed.
  apt-get install -y "${PAYLOAD_DIR}"/debs/*.deb

  tar -C /opt -xzf "${PAYLOAD_DIR}/gpa-${GPA_VERSION}.tar.gz"
  ln -sfn "/opt/gpa-${GPA_VERSION}" /opt/gpa
  stow -v -d /opt gpa -t /usr/local

  mkdir -p "/etc/skel/${OFFLINE_DIR}"
  cp -a "${PAYLOAD_DIR}/offline/." "/etc/skel/${OFFLINE_DIR}/"

  mkdir -p "$(dirname "${CRYPTO_MARKER}")"
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "${CRYPTO_MARKER}"
  et-log "Optional encryption tools installed."
}

if [[ "$1" == "--stage" ]]; then
  stage_addon
  exit 0
fi

if [[ "$1" == "--prepare" ]]; then
  prepare_offline
  exit 0
fi

if [[ "$1" == "--offline" ]]; then
  install_offline
  exit 0
fi

if [[ "$1" != "--yes" ]]; then
  echo "This installs optional encryption tools: GNU Privacy Assistant,"
  echo "Paranoia File & Text Encryption, VeraCrypt, steghide, gpg and guides."
  echo
  echo "Encryption laws differ by country: do not install these tools where"
  echo "possessing or using them is illegal. You are responsible for following"
  echo "your local laws. Amateur radio rules in most countries also prohibit"
  echo "transmitting encrypted messages."
  echo
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
