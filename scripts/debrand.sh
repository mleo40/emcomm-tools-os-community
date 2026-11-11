#!/bin/bash
# Author  : Gaston Gonzalez
# Date    : 7 May 2026
# Updated : 11 November 2026
# Purpose : Debrand the base OS
#
# Post Conditions:
# 1. EmComm Tools splash screen displays at boot (live and installed)
# 2. Calamares installer (ISO builds) shows the EmComm Tools slideshow

et-log "Debranding..."

et-log "Installing Calamares installer branding..."
mkdir -p /etc/calamares/branding
cp -v -r ../overlay/etc/calamares/branding/emcomm-tools /etc/calamares/branding/

et-log "Customizing boot screen..."
cp -v -r ../overlay/usr/share/plymouth/* /usr/share/plymouth

# Rebuild the initramfs so it carries the final splash images.
et-log "Rebuilding initramfs..."
update-initramfs -u -k all
