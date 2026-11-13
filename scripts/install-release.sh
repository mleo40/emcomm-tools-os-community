#!/bin/bash
#
# Date    : 11 November 2026
# Updated : 12 November 2026
# Purpose : Record the EmComm Tools release name where r7 had it: as
#           DISTRIB_DESCRIPTION in /etc/lsb-release (Cubic wrote it there; Debian
#           doesn't), so r7's 'et-system-info release' reads it unchanged. It is
#           shown in the conky panel and sent as JS8Call's MyInfo.
#
# Name: ETC_<RELEASE>, like r7's disk names, from the last ETC tag in this
# repository (e.g. emcomm-tools-os-community-20261111-r7-build37 gives
# ETC_R7_BUILD37). Set ET_RELEASE to override it.

. ./env.sh

if [[ -z "${ET_RELEASE}" ]]; then
  TAG=$(git -c safe.directory='*' describe --tags --abbrev=0 --match 'emcomm-tools-os-community-*' 2>/dev/null)
  BASE=$(echo "${TAG}" | sed 's/^emcomm-tools-os-community-[0-9]*-//' | tr 'a-z-' 'A-Z_')
  ET_RELEASE="ETC${BASE:+_${BASE}}"
fi

. /etc/os-release
cat > /etc/lsb-release <<EOF
DISTRIB_ID=Debian
DISTRIB_RELEASE=${VERSION_ID}
DISTRIB_CODENAME=${VERSION_CODENAME}
DISTRIB_DESCRIPTION="${ET_RELEASE}"
EOF
et-log "EmComm Tools release: ${ET_RELEASE} (/etc/lsb-release)"
