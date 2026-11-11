#!/bin/bash
#
# Date    : 11 November 2026
# Purpose : Record the EmComm Tools release name in /etc/emcomm-tools/release.
#
# Cubic used to write it into /etc/lsb-release (DISTRIB_DESCRIPTION). Debian
# has no /etc/lsb-release, so 'et-system-info release' reads this file instead.
# It is shown in the conky panel and sent as JS8Call's MyInfo, so it is a
# single word.
#
# Name: ETC-<release>-debian12, where <release> comes from the last ETC tag in
# this repository (e.g. emcomm-tools-os-community-20261027-r7-build34 gives
# ETC-r7-build34-debian12). Set ET_RELEASE to override it.

. ./env.sh

RELEASE_FILE=/etc/emcomm-tools/release

if [[ -z "${ET_RELEASE}" ]]; then
  TAG=$(git -c safe.directory='*' describe --tags --abbrev=0 --match 'emcomm-tools-os-community-*' 2>/dev/null)
  BASE=$(echo "${TAG}" | sed 's/^emcomm-tools-os-community-[0-9]*-//')
  ET_RELEASE="ETC${BASE:+-${BASE}}-debian12"
fi

mkdir -p "$(dirname "${RELEASE_FILE}")"
echo "${ET_RELEASE}" > "${RELEASE_FILE}"
et-log "EmComm Tools release: ${ET_RELEASE} (${RELEASE_FILE})"
