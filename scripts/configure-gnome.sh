#!/bin/bash
#
# Author   : Gaston Gonzalez
# Date     : 16 March 2024
# Updated  : 11 November 2026
# Purpose  : Configure GNOME

et-log "Configuring GNOME..."

# Ubuntu ships the Yaru theme and the dock, desktop icons and tray icon
# extensions built in. Debian needs them installed to match the r7 desktop.
et-log "Installing Yaru theme and GNOME extensions..."
apt install \
  yaru-theme-gtk \
  yaru-theme-icon \
  yaru-theme-gnome-shell \
  gnome-shell-extension-dashtodock \
  gnome-shell-extension-desktop-icons-ng \
  gnome-shell-extension-appindicator \
  -y

cp ../overlay/usr/share/glib-2.0/schemas/90_emcomm-tools.gschema.override \
  /usr/share/glib-2.0/schemas/

cp ../overlay/usr/share/icons/*.png \
  /usr/share/icons/
chmod 644 /usr/share/icons/et-*.png

glib-compile-schemas /usr/share/glib-2.0/schemas/

# Lock screen to one orientation
gsettings set org.gnome.settings-daemon.peripherals.touchscreen orientation-lock true
