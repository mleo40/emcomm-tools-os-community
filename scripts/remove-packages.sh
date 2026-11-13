#!/bin/bash
#
# Author   : Gaston Gonzalez
# Date     : 21 November 2022
# Updated  : 11 November 2026
# Purpose  : Remove unwanted packages

et-log "Removing unwanted packages"

# firefox-esr: r7 had no Firefox (Ubuntu's Firefox is a snap removed with snapd);
# Debian's gnome-core recommends it.
# gnome-initial-setup: Debian's first-login wizard (language, privacy/location,
# online accounts). ETC has its own first-login setup, and location services
# stay off through the gschema override (org.gnome.system.location).
apt purge \
  libreoffice-\* \
  thunderbird \
  firefox-esr \
  gnome-initial-setup \
  snapd \
  unattended-upgrades \
  -y

apt autoremove -y
