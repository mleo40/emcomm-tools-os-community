#!/bin/bash
# Author  : Gaston Gonzalez
# Date    : 7 September 2026
# Purpose : Install Veracrypt
set -e
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'et-log "\"${last_command}\" command failed with exit code $?."' ERR

. ./env.sh
. ../overlay/opt/emcomm-tools/bin/et-common

APP="veracrypt"
VERSION="1.26.29"
FILE="veracrypt-${VERSION}-Debian-12-amd64.deb"
URL="https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_${VERSION}/${FILE}"

et-log "Installing ${APP} ${VERSION}..."

if [[ ! -e "${ET_DIST_DIR}/${FILE}" ]]; then
  et-log "Downloading ${APP}: ${URL}"
  download_with_retries ${URL} ${FILE}
  mv -v ${FILE} ${ET_DIST_DIR}
fi

# ET_DOWNLOAD_ONLY=<dir>: copy the .deb there and stop (offline add-on).
if [[ -n "${ET_DOWNLOAD_ONLY}" ]]; then
  cp -v "${ET_DIST_DIR}/${FILE}" "${ET_DOWNLOAD_ONLY}/"
  exit 0
fi

et-log "Installing dependencies..."

apt install \
  pcscd \
  -y

dpkg -i "${ET_DIST_DIR}/${FILE}"
