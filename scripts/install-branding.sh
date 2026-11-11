#!/bin/bash
#
# Author  : Gaston Gonzalez
# Date    : 16 March 2024
# Updated : 11 November 2026
# Purpose : Install boot/desktop branding

et-log "Installing EmComm Tools branding"

apt install plymouth plymouth-themes -y

PLYMOUTH_DIR=/usr/share/plymouth

et-log "Installing desktop wallpaper..."
cp -v ../logos/emcomm-tools-wallpaper.png /usr/share/backgrounds/

et-log "Installing spinners..."
cp -v ../overlay/usr/share/plymouth/themes/spinner/*.png "${PLYMOUTH_DIR}/themes/spinner/"

# r7 used Ubuntu's default 'bgrt' theme, which draws the images in
# themes/spinner/. Debian defaults to its own desktop-base theme.
et-log "Setting boot splash theme..."
plymouth-set-default-theme -R bgrt

# Debian's default kernel command line is 'quiet' only; plymouth needs 'splash'.
if [[ ! -f /etc/default/grub ]]; then
  # Image build: GRUB is installed later, by the installer. Its update-grub
  # reads this drop-in.
  et-log "Enabling boot splash in GRUB (drop-in)..."
  mkdir -p /etc/default/grub.d
  echo 'GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} splash"' \
    > /etc/default/grub.d/emcomm-tools.cfg
elif ! grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=.*splash' /etc/default/grub; then
  et-log "Enabling boot splash in GRUB..."
  sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 splash"/' /etc/default/grub
  update-grub
fi

gsettings set org.gnome.desktop.background picture-uri file:////usr/share/backgrounds/emcomm-tools-wallpaper.png
gsettings set org.gnome.desktop.background picture-uri-dark file:////usr/share/backgrounds/emcomm-tools-wallpaper.png
