#!/bin/bash
#
# Date    : 11 November 2026
# Updated : 13 November 2026
# Purpose : Record the EmComm Tools release name where r7 had it: as
#           DISTRIB_DESCRIPTION in /etc/lsb-release (Cubic wrote it there; Debian
#           doesn't), so r7's 'et-system-info release' reads it unchanged. It is
#           shown in the conky panel and sent as JS8Call's MyInfo.
#
# ET_RELEASE comes from live-build/build.sh (e.g. ETC_R7_BUILD37).

. ./env.sh

ET_RELEASE="${ET_RELEASE:-ETC}"

. /etc/os-release
cat > /etc/lsb-release <<EOF
DISTRIB_ID=Debian
DISTRIB_RELEASE=${VERSION_ID}
DISTRIB_CODENAME=${VERSION_CODENAME}
DISTRIB_DESCRIPTION="${ET_RELEASE}"
EOF
et-log "EmComm Tools release: ${ET_RELEASE} (/etc/lsb-release)"
