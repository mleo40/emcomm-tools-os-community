#!/bin/bash
#
# Date    : 11 November 2026
# Purpose : Apply the EmComm Tools user setup to the user running install.sh.
#
# On Debian, the first user is created by the Debian installer *before*
# install.sh runs, so /etc/skel and /etc/adduser.conf never apply to them.
# This gives that user what a newly created user would get:
#   - primary group et-data (USERS_GID in adduser.conf)
#   - the EXTRA_GROUPS from adduser.conf (dialout, bluetooth, ...)
#   - the /etc/skel files, without overwriting anything they already have
#
# Run this last, after every other script has finished adding to /etc/skel.

. ./env.sh

ET_USER="${SUDO_USER:-}"

if [[ -z "${ET_USER}" || "${ET_USER}" == "root" ]]; then
  et-log "No non-root SUDO_USER found. Skipping existing user setup."
  exit 0
fi

ET_USER_HOME=$(getent passwd "${ET_USER}" | cut -d: -f6)
if [[ -z "${ET_USER_HOME}" || ! -d "${ET_USER_HOME}" ]]; then
  et-log "Home directory for '${ET_USER}' not found. Skipping existing user setup."
  exit 0
fi

et-log "Setting primary group of '${ET_USER}' to '${ET_GROUP}'..."
usermod -g "${ET_GROUP}" "${ET_USER}"

EXTRA_GROUPS=$(sed -n 's/^EXTRA_GROUPS="\(.*\)"/\1/p' /etc/adduser.conf)
for GROUP in ${EXTRA_GROUPS}; do
  if getent group "${GROUP}" >/dev/null; then
    usermod -a -G "${GROUP}" "${ET_USER}"
  else
    et-log "Group '${GROUP}' does not exist. Skipping."
  fi
done
et-log "Groups for '${ET_USER}': $(id -nG "${ET_USER}")"

et-log "Copying /etc/skel into ${ET_USER_HOME} (existing files are kept)..."
cp -a -n /etc/skel/. "${ET_USER_HOME}/"
chown -R "${ET_USER}:${ET_GROUP}" "${ET_USER_HOME}"

et-log "Existing user setup done. Log out and back in (or reboot) to apply it."
