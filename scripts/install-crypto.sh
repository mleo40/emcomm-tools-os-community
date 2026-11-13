#!/bin/bash
#
# Date    : 11 November 2026
# Purpose : Install the OPTIONAL encryption tools (opt-in only).
#
# GPA, PFTE, steghide and the guides (gpg, steghide, AmRRON key).
#
#   --prepare  run by install.sh: download and build everything into the
#              payload, without installing it
#   --offline  install from the payload, no network: run by the installer when
#              selected, or later with sudo

# Run from this folder (the installer calls it by full path), with ETC's
# commands on PATH.
cd "$(dirname "$(readlink -f "$0")")"
export PATH="/opt/emcomm-tools/bin:${PATH}"

. ./env.sh
. ./functions.sh

exitIfNotRoot

ADDON_DIR="${ET_HOME}/add-ons/crypto"
CRYPTO_MARKER=/etc/emcomm-tools/crypto-enabled
OFFLINE_DIR=Desktop/offline

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
    steghide
  rm -rf "${PAYLOAD_DIR}/debs/partial" "${PAYLOAD_DIR}/debs/lock"

  # PFTE .deb.
  ET_DOWNLOAD_ONLY="${PAYLOAD_DIR}/debs" ./install-pfte.sh

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

case "$1" in
  --prepare) prepare_offline ;;
  --offline) install_offline ;;
  *) echo "usage: $(basename "$0") --prepare|--offline"; exit 1 ;;
esac
