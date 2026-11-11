#!/bin/bash
#
# Author   : Gaston Gonzalez
# Date     : 21 November 2022
# Updated  : 11 November 2026
# Purpose  : Remove unwanted packages

et-log "Removing unwanted packages"

# On Debian, the 'gnome' metapackage hard-depends on LibreOffice, so purging
# LibreOffice removes 'gnome' too. Mark the rest of the desktop as manually
# installed first so 'apt autoremove' doesn't strip the GNOME apps with it.
for META in gnome task-gnome-desktop; do
  if dpkg -s "${META}" >/dev/null 2>&1; then
    apt-cache depends --installed "${META}" \
      | awk '/(Depends|Recommends):/ {print $2}' \
      | grep -v -E '^(libreoffice|firefox|<)' \
      | xargs -r apt-mark manual >/dev/null
  fi
done

# firefox-esr: r7 had no Firefox (Ubuntu's Firefox is a snap removed with snapd).
apt purge \
  libreoffice-\* \
  thunderbird \
  firefox-esr \
  snapd \
  unattended-upgrades \
  -y

apt autoremove -y
